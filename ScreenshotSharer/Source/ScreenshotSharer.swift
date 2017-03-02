/*
 MIT License
 
 Copyright (c) 2017 Yagiz Gurgul
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit

open class ScreenshotSharer: NSObject
{
    open var sharerViewController:ScreenshotSharerViewController!
    open weak var sender:UIViewController?
    
    open weak var capturedView:UIView?
    open var isCropStatusBar:Bool = false
    open var cropRect:CGRect!
    
    open var captureBlock:((UIImage?,ScreenshotSharerViewController) -> ())?
    
    open var isEnabled:Bool = true
    open var isSharerPresented:Bool = false
    
    override public init()
    {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationUserDidTakeScreenshot(notification:)), name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
    }
    
    open func registerViewCapturer(view:UIView, cropRect:CGRect, sender:UIViewController?, captureBlock:@escaping ((UIImage?,ScreenshotSharerViewController) -> ()))
    {
        self.registerViewCapturer(view: view, cropRect: cropRect, sharerViewController: ScreenshotSharerMinimal(nibName: "ScreenshotSharerMinimal", bundle: Bundle(for: ScreenshotSharerMinimal.self)), sender: sender, captureBlock: captureBlock)
    }
    
    open func registerScreenCapturer(cropStatusBar:Bool, cropRect:CGRect, sender:UIViewController?, captureBlock:@escaping ((UIImage?,ScreenshotSharerViewController) -> ()))
    {
        self.registerScreenCapturer(cropStatusBar: cropStatusBar, cropRect: cropRect, sharerViewController: ScreenshotSharerMinimal(nibName: "ScreenshotSharerMinimal", bundle: Bundle(for: ScreenshotSharerMinimal.self)), sender: sender, captureBlock: captureBlock)
    }
    
    open func registerViewCapturer(view:UIView, cropRect:CGRect, sharerViewController:ScreenshotSharerViewController?, sender:UIViewController?, captureBlock:@escaping ((UIImage?,ScreenshotSharerViewController) -> ()))
    {
        if self.sharerViewController == nil
        {
            return
        }
        
        self.capturedView = view
        self.cropRect = cropRect
        self.sharerViewController = sharerViewController
        self.sender = sender
        self.captureBlock = captureBlock
    }
    
    open func registerScreenCapturer(cropStatusBar:Bool, cropRect:CGRect, sharerViewController:ScreenshotSharerViewController?, sender:UIViewController?, captureBlock:@escaping ((UIImage?,ScreenshotSharerViewController) -> ()))
    {
        if self.sharerViewController == nil
        {
            return
        }
        
        self.isCropStatusBar = cropStatusBar
        self.cropRect = cropRect
        self.sharerViewController = sharerViewController
        self.sender = sender
        self.captureBlock = captureBlock
        
        self.capturedView = nil
    }
    
    open func unregister()
    {
        self.cropRect = nil
        self.sharerViewController = nil
        self.sender = nil
        self.captureBlock = nil
        self.capturedView = nil
    }
    
    
    func applicationUserDidTakeScreenshot(notification:NSNotification)
    {
        
        if self.isEnabled == false || self.isSharerPresented == true
        {
            return
        }
        
        if let view = capturedView, let sender = self.sender, let sharerViewController = sharerViewController
        {
            
            let image = self.takeImageOf(view: view)
            let croppedImage = self.crop(image: image, rect: self.cropRect)
            
            sender.present(sharerViewController, animated: false, completion: nil)
            sharerViewController.screenshotSharer = self
            sharerViewController.setScreenshotImage(image: croppedImage)
            
            self.isSharerPresented = true
            
            self.captureBlock?(croppedImage,sharerViewController)
            
            return
            
        }else if let window = UIApplication.shared.windows.first, let sender = self.sender, let sharerViewController = sharerViewController
        {
            
            let image = self.takeImageOf(view: window)
            
            var croppedImage = image
            
            if self.isCropStatusBar == true
            {
                croppedImage = self.cropStatusBar(image: image)
                croppedImage = self.crop(image: croppedImage, rect: self.cropRect)
                
            }else
            {
                croppedImage = self.crop(image: croppedImage, rect: self.cropRect)
            }
            
            sender.present(sharerViewController, animated: false, completion: nil)
            sharerViewController.screenshotSharer = self
            sharerViewController.setScreenshotImage(image: croppedImage)
            
            self.isSharerPresented = true
            
            self.captureBlock?(croppedImage,sharerViewController)
            
            return
        }
        
        self.captureBlock?(nil,self.sharerViewController)
    }
    
    open func takeImageOf(view:UIView) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0);
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        return image!
    }
    
    open func cropStatusBar(image:UIImage) -> UIImage
    {
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        return self.crop(image: image, rect: CGRect(x: 0, y: statusBarHeight, width: image.size.width, height: image.size.height - statusBarHeight))
    }
    
    open func crop(image:UIImage,rect:CGRect) -> UIImage
    {
        if rect == CGRect.zero
        {
            return image
        }
        
        var rect = rect
        rect.origin.x *= image.scale
        rect.origin.y *= image.scale
        rect.size.width *= image.scale
        rect.size.height *= image.scale
        
        let imageRef = image.cgImage!.cropping(to: rect)
        let image = UIImage(cgImage: imageRef!, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
    
    open func dismissSharerViewController()
    {
        sharerViewController?.dismiss(animated: true, completion: {
            
            self.isSharerPresented = false
            
        })
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
}
