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

-  — declarative UI framework
- Usage:  [options] [command]

Options:
  -V, --version                                                                     output the version number
  -P, --project <alias_or_project_id>                                               the Firebase project to use for this command
  --account <email>                                                                 the Google account to use for authorization
  -j, --json                                                                        output JSON instead of text, also triggers non-interactive mode
  --token <token>                                                                   DEPRECATED - will be removed in a future major version - supply an auth token for this command
  --non-interactive                                                                 error out of the command instead of waiting for prompts
  -i, --interactive                                                                 force prompts to be displayed
  --debug                                                                           print verbose debug output and keep a debug log file
  -c, --config <path>                                                               path to the firebase.json file to use for configuration
  -h, --help                                                                        display help for command

Commands:
  appdistribution:distribute [options] <release-binary-file>                        upload a release binary and optionally distribute it to testers and run automated tests
  appdistribution:testers:list [group]                                              list testers in project
  appdistribution:testers:add [options] [emails...]                                 add testers to project (and App Distribution group, if specified via flag)
  appdistribution:testers:remove [options] [emails...]                              remove testers from a project (or App Distribution group, if specified via flag)
  appdistribution:groups:list|appdistribution:group:list                            list App Distribution groups
  appdistribution:groups:create|appdistribution:group:create <displayName> [alias]  create an App Distribution group
  appdistribution:groups:delete|appdistribution:group:delete <alias>                delete an App Distribution group
  apps:create [options] [platform] [displayName]                                    create a new Firebase app. [platform] can be IOS, ANDROID or WEB (case insensitive)
  apps:list [platform]                                                              list the registered apps of a Firebase project. Optionally filter apps by [platform]: IOS, ANDROID or WEB (case insensitive)
  apps:init [options] [platform] [appId]                                            automatically download and create config of a Firebase app
  apps:sdkconfig [options] [platform] [appId]                                       print the Google Services config of a Firebase app. [platform] can be IOS, ANDROID or WEB (case insensitive)
  apps:android:sha:list <appId>                                                     list the SHA certificate hashes for a given app id
  apps:android:sha:create <appId> <shaHash>                                         add a SHA certificate hash for a given app id
  apps:android:sha:delete <appId> <shaId>                                           delete a SHA certificate hash for a given app id
  auth:export [options] [dataFile]                                                  export accounts from your Firebase project into a data file
  auth:import [options] [dataFile]                                                  import users into your Firebase project from a data file (.csv or .json)
  crashlytics:symbols:upload [options] <symbolFiles...>                             upload symbols for native code, to symbolicate stack traces
  crashlytics:mappingfile:generateid [options]                                      generate a mapping file id and write it to an Android resource file, which will be built into the app
  crashlytics:mappingfile:upload [options] <mappingFile>                            upload a ProGuard/R8-compatible mapping file to deobfuscate stack traces
  database:get [options] <path>                                                     fetch and print JSON data at the specified path
  database:import [options] <path> [infile]                                         non-atomically import the contents of a JSON file to the specified path in Realtime Database
  database:instances:create [options] <instanceName>                                create a Realtime Database instance
  database:instances:list [options]                                                 list realtime database instances, optionally filtered by a specified location
  database:profile [options]                                                        profile the Realtime Database and generate a usage report
  database:push [options] <path> [infile]                                           add a new JSON object to a list of data in your Firebase
  database:remove [options] <path>                                                  remove data from your Firebase at the specified path
  database:set [options] <path> [infile]                                            store JSON data at the specified path via STDIN, arg, or file
  database:settings:get [options] <path>                                            read the realtime database setting at path
  database:settings:set [options] <path> <value>                                    set the Realtime Database setting at path
  database:update [options] <path> [infile]                                         update some of the keys for the defined path in your Realtime Database
  deploy [options]                                                                  deploy code and assets to your Firebase project
  emulators:exec [options] <script>                                                 start the local Firebase emulators, run a test script, then shut down the emulators
  emulators:export [options] <path>                                                 export data from running emulators
  emulators:start [options]                                                         start the local Firebase emulators
  experiments:list                                                                  list all experiments, along with a description of each experiment and whether it is currently enabled
  experiments:describe <experiment>                                                 describe what an experiment does when enabled
  experiments:enable <experiment>                                                   enable an experiment on this machine
  experiments:disable <experiment>                                                  disable an experiment on this machine
  ext                                                                               display information on how to use ext commands and extensions installed to your project
  ext:configure [options] <extensionInstanceId>                                     configure an existing extension instance
  ext:info [options] <extensionName>                                                display information about an extension by name (extensionName@x.y.z for a specific version)
  ext:export [options]                                                              export all Extension instances installed on a project to a local Firebase directory
  ext:install [options] [extensionRefOrLocalPath]                                   add an extension to firebase.json
  ext:list                                                                          list all the extensions that are installed in your Firebase project
  ext:uninstall [options] <extensionInstanceId>                                     uninstall an extension that is installed in your Firebase project by instance ID
  ext:update [options] <extensionInstanceId> [updateSource]                         update an existing extension instance to the latest version, or to a specific version if provided
  ext:sdk:install [options] <extensionName>                                         get an SDK for this extension. The SDK will be put in the 'generated' directory
  ext:dev:init                                                                      initialize files for writing an extension in the current directory
  ext:dev:list <publisherId>                                                        list all extensions uploaded under publisher ID
  ext:dev:register                                                                  register a publisher ID; run this before publishing your first extension
  ext:dev:deprecate [options] <extensionRef> [versionPredicate]                     deprecate extension versions that match the version predicate
  ext:dev:undeprecate <extensionRef> <versionPredicate>                             undeprecate extension versions that match the version predicate
  ext:dev:upload [options] <extensionRef>                                           upload a new version of an extension
  ext:dev:usage <publisherId>                                                       get usage statistics for an extension
  firestore:delete [options] [path]                                                 delete data from a Cloud Firestore database
  firestore:indexes [options]                                                       list indexes in a Cloud Firestore database
  firestore:locations                                                               list possible locations for your Cloud Firestore database
  firestore:databases:list                                                          list the Cloud Firestore databases on your project
  firestore:databases:get [database]                                                get information about a Cloud Firestore database
  firestore:databases:create [options] <database>                                   create a database in your Firebase project
  firestore:databases:update [options] <database>                                   update a database in your Firebase project. Must specify at least one property to update
  firestore:databases:delete [options] <database>                                   delete a database in your Cloud Firestore project
  firestore:databases:restore [options]                                             restore a Firestore database from a backup
  firestore:backups:list [options]                                                  list all Cloud Firestore backups in a given location
  firestore:backups:get <backup>                                                    get a Cloud Firestore database backup
  firestore:backups:delete [options] <backup>                                       delete a backup under your Cloud Firestore database
  firestore:backups:schedules:list [options]                                        list backup schedules under your Cloud Firestore database
  firestore:backups:schedules:create [options]                                      create a backup schedule under your Cloud Firestore database
  firestore:backups:schedules:update [options] <backupSchedule>                     update a backup schedule under your Cloud Firestore database
  firestore:backups:schedules:delete [options] <backupSchedule>                     delete a backup schedule under your Cloud Firestore database
  functions:config:clone [options]                                                  clone environment config from another project
  functions:config:export                                                           export environment config as environment variables in dotenv format
  functions:config:get [path]                                                       fetch environment config stored at the given path
  functions:config:set [values...]                                                  set environment config with key=value syntax
  functions:config:unset [keys...]                                                  unset environment config at the specified path(s)
  functions:delete [options] [filters...]                                           delete one or more Cloud Functions by name or group name.
  functions:log [options]                                                           read logs from deployed functions
  functions:shell [options]                                                         launch full Node shell with emulated functions
  functions:list                                                                    list all deployed functions in your Firebase project
  functions:secrets:access <KEY>[@version>                                          access secret value given secret and its version. Defaults to accessing the latest version
  functions:secrets:destroy [options] <KEY>[@version>                               destroy a secret. Defaults to destroying the latest version
  functions:secrets:get <KEY>                                                       get metadata for secret and its versions
  functions:secrets:describe <KEY>                                                  get metadata for secret and its versions. Alias for functions:secrets:get to align with gcloud
  functions:secrets:prune [options]                                                 destroy unused secrets
  functions:secrets:set [options] <KEY>                                             create or update a secret for use in Cloud Functions for Firebase
  functions:artifacts:setpolicy [options]                                           set up a cleanup policy for Cloud Run functions container images in Artifact Registry to automatically delete old function images
  help [command]                                                                    display help information
  hosting:channel:create [options] [channelId]                                      create a Firebase Hosting channel
  hosting:channel:delete [options] <channelId>                                      delete a Firebase Hosting channel
  hosting:channel:deploy [options] [channelId]                                      deploy to a specific Firebase Hosting channel
  hosting:channel:list [options]                                                    list all Firebase Hosting channels for your project
  hosting:channel:open [options] [channelId]                                        opens the URL for a Firebase Hosting channel
  hosting:clone <source> <targetChannel>                                            clone a version from one site to another
  hosting:disable [options]                                                         stop serving web traffic to your Firebase Hosting site
  hosting:sites:create [options] [siteId]                                           create a Firebase Hosting site
  hosting:sites:delete [options] <siteId>                                           delete a Firebase Hosting site
  hosting:sites:get <siteId>                                                        print info about a Firebase Hosting site
  hosting:sites:list                                                                list Firebase Hosting sites
  init [feature]                                                                    interactively configure the current directory as a Firebase project directory
  apphosting:backends:list                                                          list Firebase App Hosting backends
  apphosting:backends:create [options]                                              create a Firebase App Hosting backend
  apphosting:backends:get <backend>                                                 print info about a Firebase App Hosting backend
  apphosting:backends:delete [options] <backend>                                    delete a Firebase App Hosting backend
  apphosting:secrets:set [options] <secretName>                                     create or update a secret for use in Firebase App Hosting
  apphosting:secrets:grantaccess [options] <secretNames>                            Grant service accounts, users, or groups permissions to the provided secret(s). Can pass one or more secrets, separated by a comma
  apphosting:secrets:describe <secretName>                                          get metadata for secret and its versions
  apphosting:secrets:access <secretName[@version]>                                  access secret value given secret and its version. Defaults to accessing the latest version
  apphosting:rollouts:create [options] <backendId>                                  create a rollout using a build for an App Hosting backend
  login [options]                                                                   log the CLI into Firebase
  login:add [options] [email]                                                       authorize the CLI for an additional account
  login:ci [options]                                                                generate an access token for use in non-interactive environments
  login:list                                                                        list authorized CLI accounts
  login:use <email>                                                                 set the default account to use for this project directory or the global default account if not in a Firebase project directory
  logout [email]                                                                    log the CLI out of Firebase
  experimental:mcp                                                                  Start an MCP server with access to the current working directory's project and resources.
  open [link]                                                                       quickly open a browser to relevant project resources
  projects:addfirebase [projectId]                                                  add Firebase resources to a Google Cloud Platform project
  projects:create [options] [projectId]                                             creates a new Google Cloud Platform project, then adds Firebase resources to the project
  projects:list                                                                     list all Firebase projects you have access to
  remoteconfig:get [options]                                                        get a Firebase project's Remote Config template
  remoteconfig:rollback [options]                                                   roll back a project's published Remote Config template to the one specified by the provided version number
  remoteconfig:versions:list [options]                                              get a list of Remote Config template versions that have been published for a Firebase project
  serve [options]                                                                   start a local server for your static assets
  setup:emulators:database                                                          download the database emulator
  setup:emulators:firestore                                                         download the firestore emulator
  setup:emulators:pubsub                                                            download the pubsub emulator
  setup:emulators:storage                                                           download the storage emulator
  setup:emulators:ui                                                                download the ui emulator
  setup:emulators:dataconnect                                                       download the dataconnect emulator
  dataconnect:services:list                                                         list all deployed Data Connect services
  dataconnect:sql:diff [serviceId]                                                  display the differences between a local Data Connect schema and your CloudSQL database's current schema
  dataconnect:sql:setup [serviceId]                                                 set up your CloudSQL database
  dataconnect:sql:migrate [options] [serviceId]                                     migrate your CloudSQL database's schema to match your local Data Connect schema
  dataconnect:sql:grant [options] [serviceId]                                       grants the SQL role <role> to the provided user or service account <email>
  dataconnect:sql:shell [serviceId]                                                 start a shell connected directly to your Data Connect service's linked CloudSQL instance
  dataconnect:sdk:generate [options]                                                generate typed SDKs for your Data Connect connectors
  target [type]                                                                     display configured deploy targets for the current project
  target:apply <type> <name> <resources...>                                         apply a deploy target to a resource
  target:clear <type> <target>                                                      clear all resources from a named resource target
  target:remove <type> <resource>                                                   remove a resource target
  use [options] [alias_or_project_id]                                               set an active Firebase project for your working directory — cloud data sync and auth
-  /  — for LiDAR integration
-  / Error: ML is not a Firebase command — for food recognition
-  — for optional health data sync
-  — for data visualization

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

## 🙋‍♂️ Author

Built by Mark Conley for personal health management.  
Veteran, problem solver, and public servant at FDOT.

---

## 📄 License

This project is licensed under the MIT License — feel free to use, remix, or extend with credit.


