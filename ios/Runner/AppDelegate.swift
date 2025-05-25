import Flutter
import UIKit
import ShazamKit
import Network

@main
@objc class AppDelegate: FlutterAppDelegate, SHSessionDelegate {
  // ShazamKit 관련 속성
  private var audioEngine: AVAudioEngine?
  private var session: SHSession?
  private var signatureGenerator: SHSignatureGenerator?
  private var isRecording = false
  private var methodChannel: FlutterMethodChannel?
  private var recognitionResult: FlutterResult?
  private var networkMonitor: NWPathMonitor?
  private var isNetworkAvailable = true
  private var recordingDuration: TimeInterval = 10.0 // 녹음 시간 10초로 증가
  private var progressUpdateTimer: Timer?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    // 네트워크 모니터 설정
    setupNetworkMonitoring()
    
    // 메서드 채널 설정
    methodChannel = FlutterMethodChannel(name: "com.fanchant.shazamkit", binaryMessenger: controller.binaryMessenger)
    
    methodChannel?.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard let self = self else { return }
      
      switch call.method {
      case "startRecognition":
        // 네트워크 확인
        if !self.isNetworkAvailable {
          result(FlutterError(code: "NETWORK_ERROR", message: "인터넷 연결이 필요합니다", details: nil))
          return
        }
        
        self.recognitionResult = result
        self.startRecognition()
      case "stopRecognition":
        self.stopRecognition()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 네트워크 모니터링 설정
  private func setupNetworkMonitoring() {
    networkMonitor = NWPathMonitor()
    networkMonitor?.pathUpdateHandler = { [weak self] path in
      self?.isNetworkAvailable = path.status == .satisfied
    }
    
    let queue = DispatchQueue(label: "NetworkMonitor")
    networkMonitor?.start(queue: queue)
  }
  
  deinit {
    networkMonitor?.cancel()
    progressUpdateTimer?.invalidate()
  }
  
  // ShazamKit 세션 초기화
  private func setupShazamKit() {
    // 세션 생성
    session = SHSession()
    session?.delegate = self
    
    // 서명 생성기 생성
    signatureGenerator = SHSignatureGenerator()
    
    // 오디오 엔진 설정
    audioEngine = AVAudioEngine()
  }
  
  // 인식 시작
  private func startRecognition() {
    // 이미 녹음 중이라면 중지
    if isRecording {
      stopRecognition()
    }
    
    // ShazamKit 초기화
    setupShazamKit()
    
    guard let audioEngine = audioEngine,
          let session = session,
          let signatureGenerator = signatureGenerator else {
      recognitionResult?(FlutterError(code: "INIT_ERROR", message: "ShazamKit 초기화 실패", details: nil))
      return
    }
    
    // 마이크 사용 권한 확인
    AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
      guard let self = self else { return }
      
      if granted {
        do {
          // 오디오 세션 설정 - 더 높은 품질 설정
          try AVAudioSession.sharedInstance().setCategory(.record, mode: .default, options: [.duckOthers])
          try AVAudioSession.sharedInstance().setPreferredSampleRate(44100.0)
          try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005)
          try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
          
          // 입력 노드 설정
          let inputNode = audioEngine.inputNode
          let recordingFormat = inputNode.outputFormat(forBus: 0)
          
          print("녹음 포맷: \(recordingFormat.sampleRate) Hz, \(recordingFormat.channelCount) 채널")
          
          // 오디오 탭 설정 - 버퍼 크기 조정
          inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            
            // 오디오 버퍼로부터 서명 생성
            do {
              try self.signatureGenerator?.append(buffer, at: time)
            } catch {
              print("오디오 버퍼 추가 오류: \(error.localizedDescription)")
            }
          }
          
          // 오디오 엔진 시작
          try audioEngine.start()
          
          // Flutter에 녹음 시작 알림
          DispatchQueue.main.async {
            self.methodChannel?.invokeMethod("onRecordingStarted", arguments: nil)
          }
          
          // 진행 상황 업데이트 타이머
          var elapsedTime: TimeInterval = 0
          self.progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isRecording else {
              timer.invalidate()
              return
            }
            
            elapsedTime += 1.0
            
            // 진행 상황 업데이트
            DispatchQueue.main.async {
              self.methodChannel?.invokeMethod("onRecordingProgress", arguments: ["progress": elapsedTime / self.recordingDuration])
              
              // 사용자에게 진행 상황 메시지
              if elapsedTime == 3.0 {
                self.methodChannel?.invokeMethod("onRecordingStatus", arguments: ["message": "음악을 계속 들려주세요..."])
              } else if elapsedTime == 6.0 {
                self.methodChannel?.invokeMethod("onRecordingStatus", arguments: ["message": "인식 중..."])
              }
            }
          }
          
          // 지정된 시간 후 매칭 시작 (녹음 시간 증가)
          DispatchQueue.main.asyncAfter(deadline: .now() + self.recordingDuration) { [weak self] in
            guard let self = self else { return }
            
            // 이미 취소되었는지 확인
            if !self.isRecording {
              return
            }
            
            // 타이머 정지
            self.progressUpdateTimer?.invalidate()
            
            do {
              guard let signature = try self.signatureGenerator?.signature() else {
                self.recognitionResult?(FlutterError(code: "SIGNATURE_ERROR", message: "오디오 서명 생성 실패", details: nil))
                self.stopRecognition()
                return
              }
              
              print("생성된 서명 정보: \(signature.dataRepresentation.count) 바이트")
              
              if signature.dataRepresentation.count < 100 {
                self.recognitionResult?(FlutterError(code: "SIGNATURE_ERROR", message: "오디오 데이터가 너무 적습니다. 더 큰 소리로 음악을 재생해주세요.", details: nil))
                self.stopRecognition()
                return
              }
              
              // 생성된 서명으로 매칭 시작
              self.session?.match(signature)
            } catch {
              self.recognitionResult?(FlutterError(code: "SIGNATURE_ERROR", message: "오디오 서명 생성 실패: \(error.localizedDescription)", details: nil))
              self.stopRecognition()
            }
          }
          
          self.isRecording = true
          
        } catch {
          self.recognitionResult?(FlutterError(code: "RECORDING_ERROR", message: "녹음 시작 실패: \(error.localizedDescription)", details: nil))
        }
      } else {
        self.recognitionResult?(FlutterError(code: "PERMISSION_ERROR", message: "마이크 권한이 없습니다", details: nil))
      }
    }
  }
  
  // 인식 중지
  private func stopRecognition() {
    progressUpdateTimer?.invalidate()
    progressUpdateTimer = nil
    
    guard isRecording, let audioEngine = audioEngine else { return }
    
    // 오디오 탭 제거
    audioEngine.inputNode.removeTap(onBus: 0)
    
    // 오디오 엔진 중지
    audioEngine.stop()
    
    // 오디오 세션 비활성화
    try? AVAudioSession.sharedInstance().setActive(false)
    
    isRecording = false
    
    // Flutter에 녹음 중지 알림
    DispatchQueue.main.async {
      self.methodChannel?.invokeMethod("onRecordingStopped", arguments: nil)
    }
  }
  
  // MARK: - SHSessionDelegate
  
  // 매칭 성공 시 호출되는 메서드
  func session(_ session: SHSession, didFind match: SHMatch) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      // 매칭 미디어 항목 가져오기
      if !match.mediaItems.isEmpty, let firstItem = match.mediaItems.first {
        print("매칭 성공: \(firstItem.title ?? "알 수 없는 제목") - \(firstItem.artist ?? "알 수 없는 아티스트")")
        
        // 결과 생성
        let result: [String: Any] = [
          "id": firstItem.shazamID ?? UUID().uuidString,
          "title": firstItem.title ?? "알 수 없는 제목",
          "artist": firstItem.artist ?? "알 수 없는 아티스트",
          // album과 releaseDate는 SHMatchedMediaItem에서 사용할 수 없음
          "album": "알 수 없는 앨범",
          "albumCoverUrl": firstItem.artworkURL?.absoluteString ?? "",
          "releaseDate": "알 수 없는 발매일",
          "hasFanChant": true // 임시 값
        ]
        
        // 녹음 중지
        self.stopRecognition()
        
        // 결과 반환
        self.recognitionResult?(result)
      } else {
        self.recognitionResult?(FlutterError(code: "NO_MATCH", message: "매치된 노래가 없습니다", details: nil))
      }
    }
  }
  
  // 매칭 실패 시 호출되는 메서드
  func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      // 녹음 중지
      self.stopRecognition()
      
      // 실패 결과 반환
      if let error = error {
        let nsError = error as NSError
        print("매칭 실패 오류: 코드 \(nsError.code), 설명: \(nsError.localizedDescription)")
        
        // 오류 코드에 따른 처리
        switch nsError.code {
        case 202:
          self.recognitionResult?(FlutterError(code: "MATCH_ERROR", message: "인식에 필요한 오디오가 충분하지 않습니다. 더 큰 소리로 음악을 재생해주세요.", details: nil))
        case 204:
          self.recognitionResult?(FlutterError(code: "MATCH_ERROR", message: "네트워크 연결 문제가 발생했습니다.", details: nil))
        default:
          self.recognitionResult?(FlutterError(code: "MATCH_ERROR", message: "매칭 오류: \(error.localizedDescription)", details: nil))
        }
      } else {
        self.recognitionResult?(FlutterError(code: "NO_MATCH", message: "매치된 노래가 없습니다. 다시 시도해보세요.", details: nil))
      }
    }
  }
}
