import QtQuick
import QtQuick3D

View3D {
    environment: SceneEnvironment {
        backgroundMode: SceneEnvironment.Color
        clearColor: "#20242b"
        antialiasingMode: SceneEnvironment.MSAA
        antialiasingQuality: SceneEnvironment.Medium
    }

    PerspectiveCamera {
        position: Qt.vector3d(0, 0, 350)
    }

    DirectionalLight {
        eulerRotation.x: -35
        eulerRotation.y: -25
        brightness: 1.2
    }

    Model {
        source: "#Cube"
        eulerRotation: Qt.vector3d(25, 35, 0)
        scale: Qt.vector3d(1.2, 1.2, 1.2)
        materials: PrincipledMaterial {
            baseColor: "#7aa2f7"
            roughness: 0.35
            metalness: 0.15
        }
    }
}
