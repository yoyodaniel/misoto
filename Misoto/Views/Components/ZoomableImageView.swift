//
//  ZoomableImageView.swift
//  Misoto
//
//  Full-screen zoomable image viewer
//

import SwiftUI
import UIKit

struct ZoomableImageView: UIViewControllerRepresentable {
    let image: UIImage
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> ZoomableImageViewController {
        let controller = ZoomableImageViewController()
        controller.image = image
        controller.onDismiss = {
            dismiss()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ZoomableImageViewController, context: Context) {}
}

class ZoomableImageViewController: UIViewController {
    var image: UIImage?
    var onDismiss: (() -> Void)?
    
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    private var minZoomScale: CGFloat = 1.0
    private var bounceBackTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        // Extend edges to cover safe area
        edgesForExtendedLayout = .all
        
        // Setup scroll view for zooming
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Extend view into safe area to cover entire sheet
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
            additionalSafeAreaInsets = .zero
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        view.addSubview(scrollView)
        
        // Setup image view
        imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = true
        scrollView.addSubview(imageView)
        
        // Setup close button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.cornerRadius = 20
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // Layout constraints - extend into safe area to cover entire sheet
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Set initial frame for imageView - will be updated in viewDidLayoutSubviews
        // We manage frame manually for proper zooming behavior
        
        // Setup double tap to zoom
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
    }
    
    @objc private func closeTapped() {
        onDismiss?()
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard view.bounds.width > 0 && view.bounds.height > 0,
              view.bounds.width.isFinite && view.bounds.height.isFinite else {
            return
        }
        
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let zoomScale = scrollView.maximumZoomScale
            
            guard zoomScale.isFinite && zoomScale > 0 else { return }
            
            let halfWidth = view.bounds.width / 2 / zoomScale
            let halfHeight = view.bounds.height / 2 / zoomScale
            let rectWidth = view.bounds.width / zoomScale
            let rectHeight = view.bounds.height / zoomScale
            
            guard halfWidth.isFinite && halfHeight.isFinite,
                  rectWidth.isFinite && rectHeight.isFinite,
                  rectWidth > 0 && rectHeight > 0 else {
                return
            }
            
            let zoomRect = CGRect(
                x: point.x - halfWidth,
                y: point.y - halfHeight,
                width: rectWidth,
                height: rectHeight
            )
            
            // Validate zoom rect before using
            guard zoomRect.size.width > 0 && zoomRect.size.height > 0,
                  zoomRect.size.width.isFinite && zoomRect.size.height.isFinite,
                  zoomRect.origin.x.isFinite && zoomRect.origin.y.isFinite else {
                return
            }
            
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateMinZoomScale()
        // Set initial frame to fill width
        if imageView.frame.width == 0 || abs(scrollView.zoomScale - minZoomScale) < 0.01 {
            centerContent()
        }
    }
    
    private func updateMinZoomScale() {
        guard let image = imageView.image else { return }
        
        let imageSize = image.size
        let scrollViewSize = scrollView.bounds.size
        
        // Guard against invalid dimensions
        guard imageSize.width > 0 && imageSize.height > 0,
              scrollViewSize.width > 0 && scrollViewSize.height > 0,
              imageSize.width.isFinite && imageSize.height.isFinite,
              scrollViewSize.width.isFinite && scrollViewSize.height.isFinite else {
            return
        }
        
        // Calculate scale to fill width exactly
        let widthScale = scrollViewSize.width / imageSize.width
        
        // Calculate scale to fill height (including safe area)
        let heightScale = scrollViewSize.height / imageSize.height
        
        // Guard against invalid scale values
        guard widthScale.isFinite && heightScale.isFinite,
              widthScale > 0 && heightScale > 0 else {
            return
        }
        
        // Use the larger scale to fill the entire view (width and height) including safe area
        // This ensures the image fills the screen nicely when first opened
        let fillScale = max(widthScale, heightScale)
        
        guard fillScale.isFinite && fillScale > 0 else { return }
        
        minZoomScale = fillScale
        scrollView.minimumZoomScale = fillScale
        if scrollView.zoomScale < fillScale {
            scrollView.zoomScale = fillScale
        }
    }
    
    private func bounceBackToOriginalSize() {
        // Cancel any existing timer
        cancelBounceBackTimer()
        
        // Check if we need to bounce back
        guard abs(scrollView.zoomScale - minZoomScale) > 0.01 else { return }
        
        // Always bounce back to original size when interaction ends
        // Use a short delay to ensure all gestures have completed
        bounceBackTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] timer in
            guard let self = self else { return }
            // Double check we still need to bounce back
            if abs(self.scrollView.zoomScale - self.minZoomScale) > 0.01 {
                self.animateBounceBack()
            }
        }
    }
    
    private func animateBounceBack() {
        // Recalculate minZoomScale to ensure it fills the view including safe area
        if let image = imageView.image {
            let imageSize = image.size
            let scrollViewSize = scrollView.bounds.size
            
            // Guard against invalid dimensions
            guard imageSize.width > 0 && imageSize.height > 0,
                  scrollViewSize.width > 0 && scrollViewSize.height > 0,
                  imageSize.width.isFinite && imageSize.height.isFinite,
                  scrollViewSize.width.isFinite && scrollViewSize.height.isFinite else {
                return
            }
            
            let widthScale = scrollViewSize.width / imageSize.width
            let heightScale = scrollViewSize.height / imageSize.height
            
            // Guard against invalid scale values
            guard widthScale.isFinite && heightScale.isFinite,
                  widthScale > 0 && heightScale > 0 else {
                return
            }
            
            // Use larger scale to fill entire view
            let fillScale = max(widthScale, heightScale)
            
            guard fillScale.isFinite && fillScale > 0 else { return }
            
            minZoomScale = fillScale
            scrollView.minimumZoomScale = fillScale
        }
        
        // Only animate if not already at minimum zoom (with small tolerance)
        guard abs(scrollView.zoomScale - minZoomScale) > 0.01 else {
            // Even if already at min zoom, ensure content is properly sized
            centerContent()
            return
        }
        
        // Use spring animation for bounce effect
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.8,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: {
                self.scrollView.zoomScale = self.minZoomScale
            },
            completion: { _ in
                // Ensure we're exactly at minimum zoom (screen width)
                self.scrollView.zoomScale = self.minZoomScale
                // Force layout update
                self.view.layoutIfNeeded()
                // Center the content and ensure width matches
                self.centerContent()
                // Update scroll view content size to match image frame
                self.scrollView.contentSize = self.imageView.frame.size
            }
        )
    }
    
    private func centerContent() {
        let boundsSize = scrollView.bounds.size
        guard let image = imageView.image else { return }
        let imageSize = image.size
        
        // Guard against invalid dimensions
        guard imageSize.width > 0 && imageSize.height > 0,
              boundsSize.width > 0 && boundsSize.height > 0,
              imageSize.width.isFinite && imageSize.height.isFinite,
              boundsSize.width.isFinite && boundsSize.height.isFinite,
              scrollView.zoomScale.isFinite && scrollView.zoomScale > 0 else {
            return
        }
        
        var frameToCenter: CGRect
        
        // At minimum zoom, ensure image fills the entire view (width and height)
        if abs(scrollView.zoomScale - minZoomScale) < 0.01 {
            // Calculate size to fill both width and height
            let widthScale = boundsSize.width / imageSize.width
            let heightScale = boundsSize.height / imageSize.height
            
            guard widthScale.isFinite && heightScale.isFinite,
                  widthScale > 0 && heightScale > 0 else {
                return
            }
            
            let fillScale = max(widthScale, heightScale)
            
            guard fillScale.isFinite && fillScale > 0 else { return }
            
            let frameWidth = imageSize.width * fillScale
            let frameHeight = imageSize.height * fillScale
            
            guard frameWidth.isFinite && frameHeight.isFinite,
                  frameWidth > 0 && frameHeight > 0 else {
                return
            }
            
            frameToCenter = CGRect(
                x: 0,
                y: 0,
                width: frameWidth,
                height: frameHeight
            )
        } else {
            // When zoomed, calculate based on zoom scale
            let scaledWidth = imageSize.width * scrollView.zoomScale
            let scaledHeight = imageSize.height * scrollView.zoomScale
            
            guard scaledWidth.isFinite && scaledHeight.isFinite,
                  scaledWidth > 0 && scaledHeight > 0 else {
                return
            }
            
            frameToCenter = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
        }
        
        // Center vertically if image is smaller than bounds
        if frameToCenter.size.height < boundsSize.height {
            let yOffset = (boundsSize.height - frameToCenter.size.height) / 2
            guard yOffset.isFinite else { return }
            frameToCenter.origin.y = yOffset
        } else {
            frameToCenter.origin.y = 0
        }
        
        // Center horizontally if image is smaller than bounds
        if frameToCenter.size.width < boundsSize.width {
            let xOffset = (boundsSize.width - frameToCenter.size.width) / 2
            guard xOffset.isFinite else { return }
            frameToCenter.origin.x = xOffset
        } else {
            // Always start at x: 0 to fill width (no black space on right)
            frameToCenter.origin.x = 0
        }
        
        // Final validation before setting frame
        guard frameToCenter.size.width.isFinite && frameToCenter.size.height.isFinite,
              frameToCenter.size.width > 0 && frameToCenter.size.height > 0,
              frameToCenter.origin.x.isFinite && frameToCenter.origin.y.isFinite else {
            return
        }
        
        imageView.frame = frameToCenter
        
        let contentWidth = max(boundsSize.width, frameToCenter.size.width)
        let contentHeight = max(boundsSize.height, frameToCenter.size.height)
        
        guard contentWidth.isFinite && contentHeight.isFinite,
              contentWidth > 0 && contentHeight > 0 else {
            return
        }
        
        scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)
    }
    
    private func cancelBounceBackTimer() {
        bounceBackTimer?.invalidate()
        bounceBackTimer = nil
    }
}

extension ZoomableImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        // Cancel bounce back timer when user starts zooming
        cancelBounceBackTimer()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Cancel bounce back timer when user starts dragging
        cancelBounceBackTimer()
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        // Always bounce back to original size when zooming ends
        bounceBackToOriginalSize()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // If not decelerating, bounce back immediately
        // If decelerating, wait for it to finish
        if !decelerate {
            bounceBackToOriginalSize()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // After deceleration ends, always bounce back to original size
        bounceBackToOriginalSize()
    }
}

