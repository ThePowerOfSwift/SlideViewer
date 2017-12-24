//
//  Redux.swift
//  PDFSlideView
//
//  Created by abeyuya on 2017/12/23.
//

import Foundation
import PDFKit
import ReSwift

public struct PDFSlideViewState: StateType {
    var currentPageIndex: Int = 0
    var isPortrait: Bool = true
    var showMenu: Bool = false
    var showThumbnail: Bool = false
    var slide: Slide = Slide()
}

struct changeCurrentPage: Action { let pageIndex: Int }
struct toggleMenu: Action {}
struct toggleThumbnail: Action {}
struct changeIsPortrait: Action { let isPortrait: Bool }
struct setSlide: Action { let slide: Slide }
struct loadImage: Action { let pageIndex: Int }

func pdfSlideViewReducer(action: Action, state: PDFSlideViewState?) -> PDFSlideViewState {
    var state = state ?? PDFSlideViewState()
    
    switch action {
        
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
        
    case let action as loadImage:
        if let image = loadImageFrom(state: state, index: action.pageIndex) {
            state.slide.images[action.pageIndex] = image
        }

    default:
        break
    }
    
    return state
}

private func loadImageFrom(state: PDFSlideViewState, index: Int) -> UIImage? {
    
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

let mainStore = Store<PDFSlideViewState>(
    reducer: pdfSlideViewReducer,
    state: nil
)
