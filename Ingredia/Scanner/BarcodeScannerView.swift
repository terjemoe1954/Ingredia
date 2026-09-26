import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    let onCode: (String) -> Void
    let onAvailabilityChanged: (Bool) -> Void
    let unavailableTitle: String
    let unavailableMessage: String
    let permissionDeniedMessage: String
    let openSettingsTitle: String

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onCode = onCode
        controller.onAvailabilityChanged = onAvailabilityChanged
        controller.unavailableTitle = unavailableTitle
        controller.unavailableMessage = unavailableMessage
        controller.permissionDeniedMessage = permissionDeniedMessage
        controller.openSettingsTitle = openSettingsTitle
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        uiViewController.onAvailabilityChanged = onAvailabilityChanged
        uiViewController.unavailableTitle = unavailableTitle
        uiViewController.unavailableMessage = unavailableMessage
        uiViewController.permissionDeniedMessage = permissionDeniedMessage
        uiViewController.openSettingsTitle = openSettingsTitle
    }
}

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    var onAvailabilityChanged: ((Bool) -> Void)?
    var unavailableTitle = ""
    var unavailableMessage = ""
    var permissionDeniedMessage = ""
    var openSettingsTitle = ""

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var unavailableView: UIView?
    private var hasDeliveredCode = false
    private var isSessionConfigured = false
    private var isViewVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        prepareCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isViewVisible = true
        hasDeliveredCode = false
        startSessionIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isViewVisible = false
        stopSessionIfNeeded()
    }

    private func prepareCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                DispatchQueue.main.async {
                    if isGranted {
                        self?.configureCamera()
                    } else {
                        self?.showCameraUnavailable(
                            message: self?.permissionDeniedMessage,
                            showsSettingsButton: true
                        )
                    }
                }
            }
        case .denied, .restricted:
            showCameraUnavailable(message: permissionDeniedMessage, showsSettingsButton: true)
        @unknown default:
            showCameraUnavailable(message: unavailableMessage)
        }
    }

    private func configureCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            showCameraUnavailable(message: unavailableMessage)
            return
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            showCameraUnavailable(message: unavailableMessage)
            return
        }
        session.addOutput(output)

        output.setMetadataObjectsDelegate(self, queue: .main)
        let supportedBarcodeTypes = Self.supportedBarcodeTypes(for: output)
        guard !supportedBarcodeTypes.isEmpty else {
            showCameraUnavailable(message: unavailableMessage)
            return
        }
        output.metadataObjectTypes = supportedBarcodeTypes

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        previewLayer = layer
        unavailableView?.removeFromSuperview()
        unavailableView = nil
        isSessionConfigured = true
        onAvailabilityChanged?(true)
        startSessionIfNeeded()
    }

    private func startSessionIfNeeded() {
        guard isViewVisible, isSessionConfigured, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    private func stopSessionIfNeeded() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    private static func supportedBarcodeTypes(for output: AVCaptureMetadataOutput) -> [AVMetadataObject.ObjectType] {
        let preferredTypes: [AVMetadataObject.ObjectType] = [.ean8, .ean13, .upce, .code128]
        return preferredTypes.filter { output.availableMetadataObjectTypes.contains($0) }
    }

    private func showCameraUnavailable(message: String?, showsSettingsButton: Bool = false) {
        onAvailabilityChanged?(false)
        unavailableView?.removeFromSuperview()

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = unavailableTitle
        titleLabel.textColor = .white
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let messageLabel = UILabel()
        messageLabel.text = message ?? unavailableMessage
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        messageLabel.font = .preferredFont(forTextStyle: .subheadline)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)

        if showsSettingsButton {
            let settingsButton = UIButton(type: .system)
            settingsButton.setTitle(openSettingsTitle, for: .normal)
            settingsButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
            settingsButton.addTarget(self, action: #selector(openAppSettings), for: .touchUpInside)
            stackView.addArrangedSubview(settingsButton)
        }

        view.addSubview(stackView)
        unavailableView = stackView

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -24),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasDeliveredCode,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else {
            return
        }

        hasDeliveredCode = true
        stopSessionIfNeeded()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onCode?(value)
    }
}
