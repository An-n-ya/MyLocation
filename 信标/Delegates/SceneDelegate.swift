//
//  SceneDelegate.swift
//  信标
//
//  Created by 张环宇 on 2022/9/29.
//

import UIKit
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    lazy var persistentContainer: NSPersistentContainer = {
        // 这里的 MyLocation 与 MyLocation.xcdatamodeld 文件对应
        let container = NSPersistentContainer(name: "MyLocation")
        container.loadPersistentStores {_, error in
            if let error = error {
                fatalError("不能从CoreData读取数据 \(error)")
            }
        }
//        print("coreData container 已创建！！！\(container.name)")
        return container
    }()
    
    lazy var managedObjectContext = persistentContainer.viewContext


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        let tabController = window!.rootViewController as! UITabBarController
        if let tabViewControllers = tabController.viewControllers {
            // 取第一个选项卡里的CurrentLocationViewController
            var navController = tabViewControllers[0] as! UINavigationController
            let controller = navController.viewControllers.first as! CurrentLocationViewController
            // 把core data context传递过去
            controller.managedObjectContext = managedObjectContext

            // 取第二个选项卡里的UINavigationController
            navController = tabViewControllers[1] as! UINavigationController
            let controller2 = navController.viewControllers.first as! LocationsViewController
            // 把core data context传递过去
            controller2.managedObjectContext = managedObjectContext
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        saveContext()
    }

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func listenForFatalCoreDataNotifications() {
        NotificationCenter.default.addObserver(
                forName: dataSaveFailedNotification,
                object: nil,
                queue: OperationQueue.main) { _ in
            let message = """
                          很抱歉！在保存数据时,MyLocation内部发生错误
                          点击 好 关闭此应用
                          """
            let alert = UIAlertController(title: "Internal Error", message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default) {_ in
                let exception = NSException(
                        name: NSExceptionName.internalInconsistencyException,
                        reason: "Fatal Core Data Error",
                        userInfo: nil)
                exception.raise()
            }
            alert.addAction(action)

            let tabController = self.window!.rootViewController!
            tabController.present(alert, animated: true, completion: nil)
        }
    }

}

