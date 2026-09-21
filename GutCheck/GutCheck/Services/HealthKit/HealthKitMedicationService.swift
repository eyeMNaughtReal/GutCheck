//
//  HealthKitMedicationService.swift
//  GutCheck
//
//  Reads the medications a person tracks in the Health app, and the doses they
//  have logged against them.
//
//  Read-only, by design and by API. The Health app owns this data: you add a
//  medication there and tap Taken there, and GutCheck reflects it. Nothing here
//  writes back — the medication types HealthKit exposes are not shareable, so
//  there is no write path to accidentally take.
//
//  This replaces an implementation built on HKClinicalRecord, which was the
//  wrong source entirely. Clinical records are FHIR documents downloaded from a
//  linked healthcare provider: they only appear if you have connected a
//  supported health system, they describe prescriptions rather than doses, and
//  nothing typed into the Health app's own Medications screen ever lands there.
//  It also requested write authorization on a clinical type, which HealthKit
//  refuses outright, so authorization threw and every fetch returned empty.
//
//  The data model has three layers, and the join between them is not the
//  obvious one:
//
//    HKMedicationConcept          the drug itself, carrying RxNorm codings
//    HKUserAnnotatedMedication    the person's tracking of it: nickname,
//                                 archived, whether it has a schedule
//    HKMedicationDoseEvent        one sample per logged dose
//
//  Dose events reference the *concept* identifier, not the annotation, so
//  resolving a person's history means reading the annotated medications first
//  and keying doses by `medication.identifier`.
//

import Foundation
import HealthKit
import UIKit

// MARK: - Dose Event

/// One dose event as the Health app recorded it.
///
/// Deliberately not `MedicationDoseLog`. That type is persisted and assumes a
/// dose was taken, whereas a dose event carries a status, a schedule context,
/// and both the expected and actual quantity. Flattening those away here would
/// throw out the parts most worth analysing, so the fidelity is kept and
/// `asDoseLog()` narrows it only where existing UI needs the older shape.
struct MedicationDoseEventRecord: Identifiable, Sendable, Hashable {

    let id: UUID

    /// The `HKMedicationConcept` identifier this dose belongs to. The link back
    /// to a medication — dose events do not reference the user's annotation.
    let conceptIdentifier: String

    /// Resolved from the annotated medication, falling back to the concept's
    /// own display text.
    let medicationName: String

    /// What the person reported taking. Nil is possible: a dose event exists
    /// for statuses where nothing was taken at all.
    let doseQuantity: Double?

    /// What the schedule expected. Non-nil only for scheduled doses, which is
    /// what makes a partial dose detectable — took 1 of 2.
    let scheduledDoseQuantity: Double?

    let unit: String

    /// When the dose was logged.
    let dateTaken: Date

    /// When it was due. Non-nil only for scheduled doses.
    let scheduledDate: Date?

    let status: HKMedicationDoseEvent.LogStatus

    let scheduleType: HKMedicationDoseEvent.ScheduleType

    /// Whether the person actually took this dose.
    ///
    /// Worth stating explicitly because most statuses are not user actions at
    /// all — see `HealthKitMedicationService.takenStatuses`.
    var wasTaken: Bool { status == .taken }

    /// True when less was taken than the schedule called for.
    var wasPartial: Bool {
        guard let doseQuantity, let scheduledDoseQuantity else { return false }
        return doseQuantity < scheduledDoseQuantity
    }

    /// Narrows to the older persisted shape for existing UI.
    ///
    /// Lossy on purpose: status and schedule context have nowhere to go in
    /// `MedicationDoseLog`. Only call this for doses that were actually taken.
    func asDoseLog() -> MedicationDoseLog {
        MedicationDoseLog(
            id: id.uuidString,
            medicationId: conceptIdentifier,
            medicationName: medicationName,
            dosageAmount: doseQuantity ?? 0,
            dosageUnit: unit,
            dateTaken: dateTaken
        )
    }
}

// MARK: - Service

/// Reads tracked medications and logged doses from the Health app.
@MainActor
@Observable final class HealthKitMedicationService {

    // MARK: Stored

    @ObservationIgnored private let healthStore = HKHealthStore()

    /// Observers on dose events, so a dose logged in Health shows up here
    /// without polling.
    @ObservationIgnored private var observers: [HKObserverQuery] = []

    @ObservationIgnored private var activationObserver: NSObjectProtocol?

    // MARK: Observable state

    /// Medications the person is currently tracking, archived ones excluded.
    var currentMedications: [MedicationRecord] = []

    /// Everything tracked, including archived, for historical lookups. A dose
    /// logged months ago may belong to a medication since archived, and
    /// dropping it would silently orphan that dose.
    var medicationHistory: [MedicationRecord] = []

    /// Logged doses, most recent first.
    var doseEvents: [MedicationDoseEventRecord] = []

    var isAuthorized = false

    var lastUpdateTime: Date?

    // MARK: Types
    //
    // Read-only. The previous implementation passed these to `toShare:` as
    // well, which HealthKit rejects for medication types.

    @ObservationIgnored
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.userAnnotatedMedicationType(),
        HKObjectType.medicationDoseEventType()
    ]

    /// Statuses that mean the person took the medication.
    ///
    /// Only `.taken` qualifies, and the set exists to make the exclusions
    /// deliberate rather than accidental. HealthKit *generates* dose events
    /// for reminder slots nobody touched — `.notInteracted` when a reminder
    /// was ignored, `.notificationNotSent` when the system failed to deliver
    /// it, `.snoozed`, and `.notLogged` when a person undoes an earlier entry.
    /// Treating those as doses would invent a medication history that never
    /// happened, which for correlation against symptoms is worse than having
    /// no data at all.
    static let takenStatuses: Set<HKMedicationDoseEvent.LogStatus> = [.taken]

    // MARK: - Authorization

    /// Whether reading medications may be attempted at all.
    ///
    /// Off, and it must stay off until the app carries whatever entitlement
    /// HealthKit wants for these types. Requesting authorization without it
    /// does not fail politely:
    ///
    ///     NSInvalidArgumentException: Authorization to read the following
    ///     types is disallowed: HKMedicationDoseEventTypeIdentifier...,
    ///     HKDataTypeUserAnnotatedMedicationConcept
    ///
    /// That is an Objective-C exception rather than a Swift error, so no
    /// `do`/`catch` can contain it — the process terminates with signal 6.
    /// Because GutCheck requests Health authorization during startup, the
    /// result was an app that closed immediately every time it was opened.
    /// Confirmed on device, not theorised.
    ///
    /// Xcode publishes no medications value for
    /// `com.apple.developer.healthkit.access` — only `health-records` and
    /// `verifiable-health-records` — and no medications capability exists in
    /// its capability list, so this most likely needs an entitlement requested
    /// from Apple. Everything below is written and compiles; it is waiting on
    /// that, not on code.
    ///
    /// Do not flip this to `true` without confirming on a real device that
    /// launch survives. A unit test cannot catch this failure.
    static let isEnabled = false

    @ObservationIgnored private var hasRequestedAuthorization = false

    /// Requests read access to tracked medications and dose events.
    func requestMedicationAuthorization() async -> Bool {
        let granted = await ensureAuthorization()
        guard granted else { return false }

        await refresh()
        await startObserving()
        return true
    }

    /// Makes sure authorization has been asked for, at most once per launch.
    ///
    /// Every fetch routes through here rather than checking a stored flag.
    /// HealthKit deliberately will not tell you whether *read* access was
    /// granted — that would leak the absence of data — so a boolean set by one
    /// call site is not something other call sites can rely on. Authorization
    /// is also now requested centrally by `HealthKitManager`, which would
    /// leave such a flag false here even though access had been granted, and
    /// every fetch would refuse to run.
    ///
    /// `requestAuthorization` is idempotent and does not re-prompt once a
    /// person has answered, so calling it is cheap and does not nag.
    @discardableResult
    private func ensureAuthorization() async -> Bool {
        // The single gate. Every fetch routes through here, so this one check
        // keeps the crashing request unreachable.
        guard Self.isEnabled else {
            isAuthorized = false
            return false
        }

        guard HKHealthStore.isHealthDataAvailable() else {
            isAuthorized = false
            return false
        }

        if hasRequestedAuthorization { return isAuthorized }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            hasRequestedAuthorization = true
            isAuthorized = true
            return true
        } catch {
            hasRequestedAuthorization = true
            isAuthorized = false
            return false
        }
    }

    // MARK: - Observation

    /// Starts watching for newly logged doses.
    ///
    /// Only dose events are observable. `HKUserAnnotatedMedicationType` is an
    /// `HKObjectType` rather than an `HKSampleType`, so it cannot back an
    /// observer query — the medication list is instead refreshed when the app
    /// becomes active, which is when a person returning from the Health app
    /// would expect to see a change.
    func startObserving() async {
        guard await ensureAuthorization() else { return }

        stopObserving()

        let doseType = HKObjectType.medicationDoseEventType()

        let query = HKObserverQuery(sampleType: doseType, predicate: nil) { [weak self] _, completion, error in
            guard error == nil else {
                completion()
                return
            }
            Task { @MainActor in
                await self?.refresh()
                completion()
            }
        }

        observers.append(query)
        healthStore.execute(query)

        do {
            try await healthStore.enableBackgroundDelivery(for: doseType, frequency: .immediate)
        } catch {
            // Background delivery is an optimisation. Without it the app still
            // refreshes on activation, so this is not worth surfacing.
        }

        activationObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    func stopObserving() {
        observers.forEach { healthStore.stop($0) }
        observers.removeAll()

        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
            self.activationObserver = nil
        }
    }

    // MARK: - Fetching

    /// Reloads medications and recent doses together.
    ///
    /// Medications are loaded first because dose events carry only a concept
    /// identifier; without the medication list a dose has no name to display.
    func refresh(since startDate: Date? = nil) async {
        guard await ensureAuthorization() else { return }

        do {
            let annotated = try await fetchAnnotatedMedications()

            medicationHistory = annotated.map(Self.medicationRecord(from:))
            currentMedications = annotated
                .filter { !$0.isArchived }
                .map(Self.medicationRecord(from:))

            let names = Dictionary(
                annotated.map { ($0.medication.identifier.description, Self.displayName(for: $0)) },
                uniquingKeysWith: { first, _ in first }
            )

            doseEvents = try await fetchDoseEvents(since: startDate, names: names)
            lastUpdateTime = Date.now
        } catch {
            // Leave the last good data in place rather than blanking the UI on
            // a transient query failure.
        }
    }

    /// The medications the person tracks in the Health app.
    func fetchAnnotatedMedications() async throws -> [HKUserAnnotatedMedication] {
        guard await ensureAuthorization() else { return [] }

        let descriptor = HKUserAnnotatedMedicationQueryDescriptor()
        return try await descriptor.result(for: healthStore)
    }

    /// Logged dose events, newest first.
    ///
    /// `names` maps concept identifiers to display names. A dose whose
    /// medication is not in the map still comes through, named from nothing
    /// better than the concept identifier, because dropping it would hide a
    /// dose the person definitely logged.
    func fetchDoseEvents(
        since startDate: Date? = nil,
        names: [String: String] = [:]
    ) async throws -> [MedicationDoseEventRecord] {
        guard await ensureAuthorization() else { return [] }

        let predicate: NSPredicate? = startDate.map {
            HKQuery.predicateForSamples(withStart: $0, end: nil, options: .strictStartDate)
        }

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.sample(type: HKObjectType.medicationDoseEventType(), predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )

        let samples = try await descriptor.result(for: healthStore)

        return samples
            .compactMap { $0 as? HKMedicationDoseEvent }
            .map { event in
                let identifier = event.medicationConceptIdentifier.description

                return MedicationDoseEventRecord(
                    id: event.uuid,
                    conceptIdentifier: identifier,
                    medicationName: names[identifier] ?? identifier,
                    doseQuantity: event.doseQuantity,
                    scheduledDoseQuantity: event.scheduledDoseQuantity,
                    unit: event.unit.unitString,
                    dateTaken: event.startDate,
                    scheduledDate: event.scheduledDate,
                    status: event.logStatus,
                    scheduleType: event.scheduleType
                )
            }
    }

    /// Doses actually taken within a date range, newest first.
    ///
    /// The status filter is the point of this method — see `takenStatuses`.
    func takenDoses(from start: Date, to end: Date) -> [MedicationDoseEventRecord] {
        doseEvents.filter { event in
            Self.takenStatuses.contains(event.status)
                && event.dateTaken >= start
                && event.dateTaken < end
        }
    }

    /// Kept for `RecentActivityViewModel`, which still asks for medications
    /// rather than doses.
    func fetchMedicationsFromHealthKit() async throws -> [MedicationRecord] {
        try await fetchAnnotatedMedications().map(Self.medicationRecord(from:))
    }

    // MARK: - Mapping

    /// The person's own name for a medication, falling back to the clinical one.
    private static func displayName(for annotated: HKUserAnnotatedMedication) -> String {
        if let nickname = annotated.nickname?.trimmingCharacters(in: .whitespacesAndNewlines),
           !nickname.isEmpty {
            return nickname
        }
        return annotated.medication.displayText
    }

    private static func medicationRecord(from annotated: HKUserAnnotatedMedication) -> MedicationRecord {
        let concept = annotated.medication

        return MedicationRecord(
            id: concept.identifier.description,
            createdBy: "",
            name: displayName(for: annotated),
            // Amount is deliberately zero. A medication concept carries no dose
            // amount — in this model the amount belongs to each dose event, and
            // inventing one here would put a number on screen that Health never
            // said. Frequency reflects only whether reminders are set up;
            // HealthKit does not expose the schedule itself.
            dosage: MedicationDosage(
                amount: 0,
                unit: "",
                frequency: annotated.hasSchedule ? .custom : .asNeeded,
                instructions: nil
            ),
            // The Health app does not date when tracking began, and guessing
            // would be worse than admitting it, so the record is open-ended and
            // `isArchived` carries the only real lifecycle signal there is.
            startDate: Date.distantPast,
            endDate: nil,
            isActive: !annotated.isArchived,
            notes: nil,
            source: .healthKit,
            privacyLevel: .private,
            healthKitUUID: nil
        )
    }

    // MARK: - Cleanup

    deinit {
        observers.forEach { healthStore.stop($0) }
        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
        }
    }
}
