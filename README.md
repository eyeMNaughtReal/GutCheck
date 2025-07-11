# GutCheck 🍽️💩📊

**GutCheck** is a personal iOS application designed to help users track and analyze their food intake and gastrointestinal symptoms using the power of LiDAR, AI, and Firebase.

---

## 🚀 Project Goals

- **Identify food triggers** that cause bloating, pain, and irregular bowel movements.
- **Leverage iPhone LiDAR** to estimate portion sizes.
- **Use AI to recognize food items** in meal photos.
- **Track nutritional details** (macros, allergens, additives, etc.)
- **Log bowel movements** with medical-grade accuracy using the Bristol stool chart.
- **Analyze patterns** between meals and symptoms to detect likely triggers.
- **Visualize trends** through charts, graphs, and trigger heatmaps.
- **Support export to CSV** and optionally sync with Apple Health.

---

## 🧠 Key Features

- 🔹 **LiDAR-based portion scanning**
- 🔹 **Camera & photo-based meal capture**
- 🔹 **Barcode scanning + manual food/recipe input**
- 🔹 **AI-generated food recognition & nutrition tagging**
- 🔹 **Bowel log with Bristol chart, pain, urgency**
- 🔹 **Daily/weekly history view with filters**
- 🔹 **AI-driven trigger score analysis**
- 🔹 **Export data as CSV / sync with Apple HealthKit**
- 🔹 **Charts & graphs to visualize patterns and severity**

---

## 🧰 Tech Stack

- `SwiftUI` — declarative UI framework
- `Firebase` — cloud data sync and auth
- `ARKit` / `SceneDepth` — for LiDAR integration
- `Core ML` / `Firebase ML Kit` — for food recognition
- `HealthKit` — for optional health data sync
- `Swift Charts` — for data visualization

---

## 🔒 Privacy Focus

GutCheck is built with privacy in mind:
- Data is stored securely in Firebase, scoped to the authenticated user
- No third-party tracking or analytics
- Offline-first with sync support when internet is available

---

## 📅 Development Plan

| Phase         | Features                                                   |
|---------------|------------------------------------------------------------|
| ✅ Phase 1    | Project planning, GitHub setup, Firebase integration        |
| 🚧 Phase 2    | Meal logging UI, manual + barcode + camera input           |
| ⏳ Phase 3    | LiDAR + camera fusion for food scanning                    |
| ⏳ Phase 4    | AI ingredient recognition and nutrition tagging             |
| ⏳ Phase 5    | Bowel logging + symptom analytics                          |
| ⏳ Phase 6    | Data visualization + trigger scoring                        |
| ⏳ Phase 7    | CSV export, HealthKit sync, UI polish                      |

---

## UI

Primary: Plum #7D5BA6
Accent: Mint Green #A1E3D8
Background: Ivory #FFFDF6
Text: Dark Plum #2D1B4E
Secondary: Pale Orange #FFD6A5

---

## 🙋‍♂️ Author

Built by Mark Conley for personal health management.  
Veteran, problem solver, and public servant at FDOT.

---

## 📄 License

This project is licensed under the MIT License — feel free to use, remix, or extend with credit.
