import AVFoundation
import AppKit

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            print("MacCam: No photo data")
            return
        }

        let saveDir = SettingsManager.shared.saveDirectory
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "MacCam_\(formatter.string(from: Date())).jpg"
        let fileURL = saveDir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            print("MacCam: Saved \(fileURL.path)")
        } catch {
            print("MacCam: Save failed - \(error)")
        }

        DispatchQueue.main.async { [weak self] in
            self?.lastSavedURL = fileURL
            self?.showSaveConfirmation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self?.showSaveConfirmation = false
            }
        }
    }
}
