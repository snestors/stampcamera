allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Overrides para plugins:
// - NDK: los plugins piden el 28.2.x de Flutter 3.44, que no cabe en el disco
//   del SDK; se fuerza el 28.0 ya instalado (diferencia solo patch-level).
// - compileSdk: file_picker 8.x declara 34 y los plugins first-party exigen 36.
subprojects {
    if (!state.executed) {
        afterEvaluate {
            extensions.findByName("android")?.let { androidExt ->
                runCatching {
                    androidExt.javaClass
                        .getMethod("setNdkVersion", String::class.java)
                        .invoke(androidExt, "28.0.13004108")
                }
                runCatching {
                    androidExt.javaClass
                        .getMethod("setCompileSdk", Integer::class.java)
                        .invoke(androidExt, 36)
                }.recoverCatching {
                    androidExt.javaClass
                        .getMethod("compileSdkVersion", Integer.TYPE)
                        .invoke(androidExt, 36)
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
