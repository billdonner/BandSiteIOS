//
//  ViewController.swift
//  Grubeler
//
//  Created by william donner on 2/3/20.
//  Copyright © 2020 midnightrambler. All rights reserved.
//

import UIKit
import URLSurfer
import LinkGrubber
import BandSite

let LOGGINGLEVEL = LoggingLevel.verbose
// these functions must be supplied by the caller of LinkGrubber.grub()

// for testing only , we'll use kanna


public struct  FileTypeFuncs:BandSiteProt {
    
    var bandfacts:BandInfo
    public init(bandfacts:BandInfo) {self.bandfacts = bandfacts}
    
    
    public func pageMakerFunc(_ props: CustomPageProps, _ links: [Fav]) throws {
       let _    = try AudioHTMLSupport(bandinfo: bandfacts,
                                   lgFuncs: self ).audioListPageMakerFunc(props:props,links:links)
    }
    
    public func matchingFunc(_ u: URL) -> Bool {
        return  u.absoluteString.hasPrefix(bandfacts.matchingURLPrefix)
    }
    
    public func scrapeAndAbsorbFunc ( theURL:URL, html:String ) throws ->  ScrapeAndAbsorbBlock {
        let x   = HTMLExtractor.extractFrom (  html:html )
        return HTMLExtractor.converttoScrapeAndAbsorbBlock(x,relativeTo:theURL)
    }

    public func isImageExtensionFunc (_ s:String) -> Bool {
         ["jpg","jpeg","png"].includes(s)
     }

    public func isAudioExtensionFunc(_ s:String) -> Bool {
        ["mp3","mpeg","wav"].includes(s)
    }
    public func isMarkdownExtensionFunc(_ s:String) -> Bool{
        ["md", "markdown", "txt", "text"].includes(s)
    }
    public func isNoteworthyExtensionFunc(_ s: String) -> Bool {
        isImageExtensionFunc(s) || isMarkdownExtensionFunc(s)
    }
   public  func isInterestingExtensionFunc (_ s:String) -> Bool {
        isImageExtensionFunc(s) || isAudioExtensionFunc(s)
    }
}


class BandSiteViewController: UIViewController {
    
    func createBigDataFiles() -> URL {
        let td =  FileManager.default.temporaryDirectory
        let url1 = td.appendingPathComponent("BigData.csv")
        do {
            try  "".write(to: url1, atomically: true, encoding: .utf8)
        }
        catch {
            fatalError("could not create bigdata.csv")
        }
        let url2 = td.appendingPathComponent("BigData.json")
        do {
            try  "".write(to: url2, atomically: true, encoding: .utf8)
        }
        catch {
            fatalError("could not create bigdata.json")
        }
        return td
    }
    
    @IBOutlet weak var step2ActivityIndicator: UIActivityIndicatorView!
    var step1ReturnedURLs : [URL] = []
    
    @IBOutlet weak var step3Button: UIButton!
    @IBOutlet weak var step2Button: UIButton!
    @IBOutlet weak var step1Button: UIButton!
    @IBOutlet weak var topMessage: UILabel!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var step1Results: UILabel!
    @IBOutlet weak var step2Results: UILabel!
    @IBOutlet weak var step3Results: UILabel!
    
    private func buttset(_ b1:Bool,_ b2:Bool,_ b3:Bool) {
        step1Button.isEnabled = b1
        step2Button.isEnabled = b2
        step3Button.isEnabled = b3
        
        step1Button.isSelected = b1
        step2Button.isSelected = b2
        step3Button.isSelected = b3
    }
    
    private func pickfont(_ b:Bool) -> UIFont {
        b ? UIFont.preferredFont(forTextStyle:.body) :
            UIFont.preferredFont(forTextStyle:.footnote)
    }
    
    private func resultset(_ b1:Bool,_ b2:Bool,_ b3:Bool) {
        step1Results.font = pickfont(b1)
        step2Results.font = pickfont(b2)
        step3Results.font = pickfont(b3)
    }
    
    private func hiddenset(_ b1:Bool,_ b2:Bool,_ b3:Bool) {
        if b1 { step1Results.text =  "CHOOSE ROOTS" }
        if b2 { step2Results.text =   "GRUB FOR LINKS" }
        if b3 { step3Results.text =  "ANALYZE AND EXPORT" }
    }
    
    func setupInitialState() {
        topMessage.text = "Step 1- Surf and Pick Pages of Interest"
        hiddenset(true,true,true)
        buttset(true, false, false)
        resultset(false,false,false)
        step1Results.text = "roots results"
        step2Results.text =  "grub results"
        step3Results.text =  "export results"
    }
    
    @IBAction func step1Action(_ sender: Any) {
        // present a URLSurfer and then
        var vc: URLSurfPicker.URLPickerNavigationController?
        func dism() {
            if vc != nil { vc?.dismiss(animated:true) { print("dismissed \(vc!)"); return }
            }
        }
        
        vc = URLSurfPicker.make([URL(string:"https://billdonner.com/halfdead/")!,  URL(string:"https://www.swiftbysundell.com/")!,URL(string:"https://www.hackingwithswift.com/")!, URL(string:"https://google.com")!],
                                foreach: {[weak self] url in
                                    guard let self=self else {return}
                                    
                                    DispatchQueue.main.async {
                                        self.step1ReturnedURLs = [url]
                                        self.step1Results.text =  "\(url) picked"
                                        self.topMessage.text = "Step 2- Crawl for Interesting Files"
                                        self.hiddenset(false,true,true)
                                        self.buttset (false,true,false)
                                        self.resultset(true,false,false)
                                        self.view.setNeedsDisplay()
                                        dism()
                                    }
            },
                                finally: { allurl in print ("gotall \(allurl)") })
        present(vc!, animated: true)
    }
    
    @IBAction func step2Action(_ sender: Any) {
        let root = RootStart(name:"Grubeler",url:self.step1ReturnedURLs[0])
        do{
            step2ActivityIndicator.startAnimating()
            try LinkGrubber().grub(roots:[root],
                                   opath:createBigDataFiles().absoluteString,
                                   logLevel:  .verbose,
                                   lgFuncs:FileTypeFuncs(bandfacts: bandfacts) ){
                                    [weak self] crawlstats in
                                    guard let self = self else {return}
                                    DispatchQueue.main.async {
                                        self.topMessage.text = "Step 3 - Export Files for Analysis"
                                        self.step2Results.text =  "\(crawlstats.added) scanned, \(crawlstats.count1) urls added, \(crawlstats.count2) urls rejected"
                                        self.hiddenset(false,false,true)
                                        self.buttset(false,false,true)
                                        self.resultset(false,true,false)
                                        self.step2ActivityIndicator.stopAnimating()
                                        
                                        self.view.setNeedsDisplay()
                                    }
            }
        }
        catch {
            // if we cant grub just disable buttons and show an error
            self.step2Results.text =  "step 2 failed -\(error)"
            self.buttset(false,false,false)
            self.view.setNeedsDisplay()
        }
    }
    
    @IBAction func step3Action(_ sender: Any) {
        topMessage.text = " All Done - Exports Are Done"
        hiddenset(false,false,false)
        buttset(false , false, false)
        resultset(false,false,true)
        view.setNeedsDisplay()
    }
    
    @IBAction func resetAction(_ sender: Any) {
        // setup as if we've never done anything
        setupInitialState()
        view.setNeedsDisplay()
    }
    
    @IBAction func infoAction(_ sender: Any) {
        // nothing yet
    }
    override func viewDidAppear(_ animated: Bool) {
        self.view.setNeedsDisplay() // may have been altered in a closure called back from another controller
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupInitialState()
    }
}

