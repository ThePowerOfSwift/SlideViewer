//
//  Redux.swift
//  SlideViewer
//
//  Created by abeyuya on 2017/12/23.
//

import Foundation
import PDFKit
import ReSwift

public struct SlideViewerState: StateType {
    var currentPageIndex: Int = 0
    var isPortrait: Bool = true
    var showMenu: Bool = false
    var showThumbnail: Bool = false
    var slide: Slide = Slide()
    var moveToSlideIndex: Int? = nil
    var moveToThumbnailIndex: Int? = nil
    var thumbnailHeight: CGFloat? = nil
}

internal struct stateReset: Action {}
internal struct changeCurrentPage: Action { let pageIndex: Int }
internal struct toggleMenu: Action {}
internal struct toggleThumbnail: Action {}
internal struct changeIsPortrait: Action { let isPortrait: Bool }
internal struct setSlide: Action { let slide: Slide }
internal struct setImage: Action {
    let pageIndex: Int
    let originalImage: UIImage
    let thumbnailImage: UIImage?
}
internal struct moveToSlide: Action { let pageIndex: Int? }
internal struct moveToThumbnail: Action { let pageIndex: Int? }
internal struct setThumbnailHeight: Action { let height: CGFloat }

internal func slideViewerReducer(action: Action, state: SlideViewerState?) -> SlideViewerState {
    var state = state ?? SlideViewerState()
    
    switch action {
        
    case _ as stateReset:
        state = SlideViewerState()
        
    case let action as changeCurrentPage:
        state.currentPageIndex = action.pageIndex
        
    case _ as toggleMenu:
        state.showMenu = !state.showMenu
        
    case _ as toggleThumbnail:
        state.showThumbnail = !state.showThumbnail
        
    case let action as changeIsPortrait:
        state.isPortrait = action.isPortrait
        
    case let action as setSlide:
        state.slide = action.slide
        
    case let action as setImage:
        state.slide.images[action.pageIndex] = action.originalImage
        state.slide.thumbnailImages[action.pageIndex] = action.thumbnailImage

    case let action as moveToSlide:
        state.moveToSlideIndex = action.pageIndex
        
    case let action as moveToThumbnail:
        state.moveToThumbnailIndex = action.pageIndex
        
    case let action as setThumbnailHeight:
        state.thumbnailHeight = action.height
        
    default:
        break
    }
    
    return state
}

internal func loadImage(state: SlideViewerState, index: Int) {
    DispatchQueue.global(qos: .default).async {
        guard state.slide.images[index] == nil else { return }
        guard let image = loadImageFrom(state: state, index: index) else { return }
        let thumbnailImage = createThumbnailImage(originalImage: image)
        let thumbnailHeight = thumbnailImage?.size.height
        
        DispatchQueue.main.async {
            if state.thumbnailHeight == nil, let height = thumbnailHeight {
                mainStore.dispatch(setThumbnailHeight(height: height))
            }
            mainStore.dispatch(setImage(
                pageIndex: index,
                originalImage: image,
                thumbnailImage: thumbnailImage
            ))
        }
    }
}

private func loadImageFrom(state: SlideViewerState, index: Int) -> UIImage? {
    
    if let pdfDocument = state.slide.pdfDocument {
        return loadImageFrom(pdfDocument: pdfDocument, index: index)
    }
    
    return nil
}

private func loadImageFrom(pdfDocument: PDFDocument, index: Int) -> UIImage? {
    guard let page = pdfDocument.page(at: index) else { return nil }
    let pageRect = page.bounds(for: .mediaBox)
    let renderer = UIGraphicsImageRenderer(size: pageRect.size)
    let image = renderer.image { ctx in
        UIColor.white.set()
        ctx.fill(pageRect)
        
        ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
        ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
        
        ctx.cgContext.drawPDFPage(page.pageRef!)
    }
    return image
}


private func createThumbnailImage(originalImage: UIImage) -> UIImage? {
    let thumbnailHeight = originalImage.size.height * (Config.shared.thumbnailViewWidth / originalImage.size.width)
    return originalImage.resize(size: CGSize(width: Config.shared.thumbnailViewWidth, height: thumbnailHeight))
}

fileprivate extension UIImage {
    func resize(size _size: CGSize) -> UIImage? {
        let widthRatio = _size.width / size.width
        let heightRatio = _size.height / size.height
        let ratio = widthRatio < heightRatio ? widthRatio : heightRatio
        
        let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0)
        draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}

internal let mainStore = Store<SlideViewerState>(
    reducer: slideViewerReducer,
    state: nil
)
