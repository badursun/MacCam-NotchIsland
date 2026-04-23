import AVFoundation
import AppKit

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation() else { return }

        let picturesURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
        let macCamFolder = picturesURL.appendingPathComponent("MacCam")
        try? FileManager.default.createDirectory(at: macCamFolder, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "MacCam_\(formatter.string(from: Date())).jpg"
        let fileURL = macCamFolder.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            DispatchQueue.main.async { [weak self] in
                self?.lastSavedURL = fileURL
                self?.showSaveConfirmation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.showSaveConfirmation = false
                }
            }
        } catch {
            print("Failed to save photo: \(error)")
        }
    }
}
