//
//  AppDelegate.swift
//  DemoTar
//
//  Created by Konstantin Bukreev on 24.01.17.
//  Copyright © 2017 Konstantin Bukreev. All rights reserved.
//

import UIKit
import TarballKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        print("run at \(docsDir)")
        copySample("sample", destination: docsDir)

        self.window = UIWindow(frame: UIScreen.main.bounds)
        let vc = FolderViewController(folderPath: docsDir)
        self.window!.rootViewController = UINavigationController(rootViewController:vc)
        self.window!.makeKeyAndVisible()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    func copySample(_ sample: String, destination: String) {

        let dstPath = destination + "/" + sample + ".tar"
        guard !FileManager.default.fileExists(atPath: dstPath) else { return }
        guard let srcPath = Bundle.main.path(forResource: sample, ofType: "tar") else { return }
        try? FileManager.default.copyItem(atPath: srcPath, toPath: dstPath)
        print("\(sample) copied")
    }
}
