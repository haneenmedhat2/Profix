//
//  IntroVM.swift
//  Profix
//
//  Created by Haneen on 08/12/2025.
//


import Foundation
import Combine
import Kingfisher

protocol IntroVMProtocol {
    
    var introPublisher: Published<[IntroModel]?>.Publisher { get }
    
    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    var introList : [IntroModel] { get set }
    var currentIndex : Int { get set }
    
    func introRequest()
}

final class IntroVM: BaseViewModel,IntroVMProtocol {
    private var imagePrefetcher: ImagePrefetcher?
    @Published var intro: [IntroModel]?

    var introPublisher: Published<[IntroModel]?>.Publisher { $intro }

    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    var introList : [IntroModel] = []
    var currentIndex : Int = 0


    func introRequest(){
        guard !isLoading, intro == nil else { return }
        isLoading = true
        Task { @MainActor in
            do {
                let result = try await getAllRequest(AuthEndpoints.introRequest())
                isLoading = false
                introList = result.data?.intros ?? []
                let urls = introList.compactMap { $0.image }.compactMap(URL.init(string:))
                imagePrefetcher = ImagePrefetcher(urls: urls, options: IntroImageLoading.options)
                imagePrefetcher?.maxConcurrentDownloads = 2
                imagePrefetcher?.start()
                intro = result.data?.intros
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }

    deinit {
        imagePrefetcher?.stop()
    }
}
