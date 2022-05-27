import UIKit
import AVFoundation

class SoundViewController: UIViewController {
    
    @IBOutlet weak var grabarButton: UIButton!
    
    @IBOutlet weak var reproducirButton: UIButton!
    
    
    @IBOutlet weak var nombreTextField: UITextField!
    
    @IBOutlet weak var agregarButton: UIButton!
    

    @IBOutlet weak var volumeBar: UISlider!
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    @IBOutlet weak var duracionOutlet: UILabel!
    
    var grabarAudio:AVAudioRecorder?
    var reproducirAudio:AVAudioPlayer?
    var audioURL:URL?
    var timer: Timer?
    
    var tiempo:Timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurarGrabacion()
        reproducirButton.isEnabled = false
        agregarButton.isEnabled = false
        progressBar.isHidden = true

        // Do any additional setup after loading the view.
    }
    
    func configurarGrabacion(){
        do {
            // creando sesion del audio
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: [])
            try session.overrideOutputAudioPort(.speaker)
            try session.setActive(true)
            
            // creando direccion para el archivo del audio
            let basePath:String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let pathComponents = [basePath,"audio.m4a"]
            audioURL = NSURL.fileURL(withPathComponents: pathComponents)!
            
            // impresion de rutas
            print("****************************")
            print(audioURL!)
            print("****************************")
            // crear opciones para el grabador de audio
            var settings:[String:AnyObject] = [:]
            
            settings[AVFormatIDKey] = Int(kAudioFormatMPEG4AAC) as AnyObject?
            settings[AVSampleRateKey] = 44100.0 as AnyObject?
            settings[AVNumberOfChannelsKey] = 2 as AnyObject?
            
            // crear el objeto de grabacion
            grabarAudio = try AVAudioRecorder(url: audioURL!, settings:  settings)
            grabarAudio!.prepareToRecord()
            
        } catch let error as NSError {
            print(error)
        }
    }
    
    @IBAction func grabarTapped(_ sender: Any) {
        if grabarAudio!.isRecording {
            grabarAudio?.stop()
            grabarButton.setTitle("GRABAR", for: .normal)
            reproducirButton.isEnabled = true
            agregarButton.isEnabled = true
            progressBar.isHidden = true
            tiempo.invalidate()
        } else {
            grabarAudio?.record()
            grabarButton.setTitle("DETENER", for: .normal)
            // Se crea el timer para que funcione como contador.
            tiempo = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(tiempoTotal), userInfo: nil, repeats: true)
            reproducirButton.isEnabled = false
            progressBar.isHidden = false
            self.startTimer()
        }
    }
    
    @IBAction func reproducirTapped(_ sender: Any) {
        do {
            try reproducirAudio = AVAudioPlayer(contentsOf: audioURL!)
            reproducirAudio!.play()
            reproducirAudio?.volume = volumeBar.value
            progressBar.isHidden = false
            self.startTimer()
            print("Reproduciendo")
        } catch {}
        
    }
    
    @objc func tiempoTotal()-> Void{
        let tiempoEnHora = Int(grabarAudio!.currentTime)
        let minuto = (tiempoEnHora % 3600) / 60
        let segundo = (tiempoEnHora % 3600) % 60
        var tiempoConFormato = ""
        tiempoConFormato += String(format:"%02d", minuto)
        tiempoConFormato += ":"
        tiempoConFormato += String(format: "%02d", segundo)
        tiempoConFormato += ""
        duracionOutlet.text! = tiempoConFormato
    }
    
    
    func startTimer() {
             timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateRecordingProgress), userInfo: nil, repeats: true)
            timer?.fire()
        }
    
    @objc func updateRecordingProgress() {
            //update your UIProgressView here
            if reproducirAudio != nil && (reproducirAudio?.duration ?? TimeInterval(0)) > TimeInterval(0) {
                self.progressBar.progress = Float(((reproducirAudio?.currentTime ?? 0) / (reproducirAudio?.duration ?? 1)))
            }
        }
    
    
    @IBAction func agregarTapped(_ sender: Any) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let grabacion = Grabacion(context: context)
        grabacion.nombre = nombreTextField.text
        let asset = AVURLAsset(url: audioURL!)
        let audioDuration = asset.duration
        let audioDurationSeconds = CMTimeGetSeconds(audioDuration)
        let hours:Int = Int(audioDurationSeconds / 3600)
        let minutes:Int = Int(audioDurationSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds:Int = Int(audioDurationSeconds.truncatingRemainder(dividingBy: 60))
        let finalFormat: String = String(format: "%i:%02i:%02i", hours, minutes, seconds)
        print(finalFormat)
        grabacion.duracion = String(finalFormat)
        grabacion.audio = NSData(contentsOf: audioURL!)! as Data
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        navigationController!.popViewController(animated: true)
        
    }
    
}
