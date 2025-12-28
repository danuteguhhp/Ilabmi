// Import ini mungkin diperlukan
import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// 👇👇 BLOK PENTING (DENGAN PERBAIKAN)
buildscript {
    // PERBAIKAN: Tentukan versi Kotlin sebagai variabel lokal
    val kotlinVersion = "2.2.21" 

    // Tetapkan juga ke 'extra' agar bisa dibaca file .gradle lain
    extra.set("kotlin_version", kotlinVersion) 

    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Plugin build Android
        classpath("com.android.tools.build:gradle:7.3.0")

        // 👇 PERBAIKAN: Gunakan variabel lokal 'kotlinVersion'
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion") 

        // Plugin Google Services untuk membaca file google-services.json
        classpath("com.google.gms:google-services:4.4.1")
    }
}

// Ini adalah kode yang sudah Anda miliki sebelumnya
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}