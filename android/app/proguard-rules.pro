# WorkManager (used by Mobile Ads) creates its Room implementation reflectively.
# AGP 9 / R8 full mode must retain the generated no-argument constructor.
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.InputMerger {
    public <init>();
}
