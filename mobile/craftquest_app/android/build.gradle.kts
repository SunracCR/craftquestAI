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

// AGP 9 exige que un módulo que depende de un AAR compilado con compileSdk 36
// también compile contra 36. Varios plugins de Flutter siguen en 34.
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        val setCompileSdk = androidExt.javaClass.methods.firstOrNull { method ->
            method.name == "setCompileSdk" && method.parameterCount == 1
        }
        if (setCompileSdk != null) {
            setCompileSdk.invoke(androidExt, 36)
        } else {
            androidExt.javaClass.methods.firstOrNull { method ->
                method.name == "compileSdkVersion" &&
                    method.parameterCount == 1 &&
                    method.parameterTypes[0] == Int::class.javaPrimitiveType
            }?.invoke(androidExt, 36)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
