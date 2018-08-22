//
//  CandleStickChartRenderer.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif


open class CandleStickChartRenderer: LineScatterCandleRadarRenderer
{
    @objc open weak var dataProvider: CandleChartDataProvider?
    
    @objc public init(dataProvider: CandleChartDataProvider, animator: Animator, viewPortHandler: ViewPortHandler)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        
        self.dataProvider = dataProvider
    }
    
    open override func drawData(context: CGContext)
    {
        guard let dataProvider = dataProvider, let candleData = dataProvider.candleData else { return }

        // If we redraw the data, remove and repopulate accessible elements to update label values and frames
        accessibleChartElements.removeAll()

        // Make the chart header the first element in the accessible elements array
        if let chart = dataProvider as? CandleStickChartView {
            let element = createAccessibleHeader(usingChart: chart,
                                                 andData: candleData,
                                                 withDefaultDescription: "CandleStick Chart")
            accessibleChartElements.append(element)
        }

        for set in candleData.dataSets as! [ICandleChartDataSet]
        {
            if set.isVisible
            {
                drawDataSet(context: context, dataSet: set)
            }
        }
    }
    
    private var _shadowPoints = [CGPoint](repeating: CGPoint(), count: 4)
    private var _rangePoints = [CGPoint](repeating: CGPoint(), count: 2)
    private var _openPoints = [CGPoint](repeating: CGPoint(), count: 2)
    private var _closePoints = [CGPoint](repeating: CGPoint(), count: 2)
    private var _bodyRect = CGRect()
    private var _lineSegments = [CGPoint](repeating: CGPoint(), count: 2)
    
    @objc open func drawDataSet(context: CGContext, dataSet: ICandleChartDataSet)
    {
        guard
            let dataProvider = dataProvider,
            let chart = dataProvider as? CandleStickChartView
            else { return }

        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        
        let phaseY = animator.phaseY
        let barSpace = dataSet.barSpace
        let showCandleBar = dataSet.showCandleBar
        let entryCount = dataSet.entryCount
        
        _xBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)
        
        context.saveGState()
        
        context.setLineWidth(dataSet.shadowWidth)

        for j in stride(from: _xBounds.min, through: _xBounds.range + _xBounds.min, by: 1)
        {
            // get the entry
            guard let e = dataSet.entryForIndex(j) as? CandleChartDataEntry else { continue }
            
            let xPos = e.x
            
            let open = e.open
            let close = e.close
            let high = e.high
            let low = e.low
            
            let doesContainMultipleDataSets = (dataProvider.candleData?.dataSets.count ?? 1) > 1
            var accessibilityMovementDescription = "neutral"
            var accessibilityRect = CGRect(x: CGFloat(xPos) + 0.5 - barSpace,
                                           y: CGFloat(low * phaseY),
                                           width: (2 * barSpace) - 1.0,
                                           height: (CGFloat(abs(high - low) * phaseY)))
            trans.rectValueToPixel(&accessibilityRect)

            if showCandleBar
            {
                if open != close {
                    let barColor = dataSet.decreasingColor ?? dataSet.color(atIndex: j)
                    _bodyRect.origin.x = CGFloat(xPos) - 0.5 + barSpace
                    _bodyRect.origin.y = CGFloat(close * phaseY)
                    _bodyRect.size.width = (CGFloat(xPos) + 0.5 - barSpace) - _bodyRect.origin.x
                    _bodyRect.size.height = CGFloat(open * phaseY) - _bodyRect.origin.y
                    
                    trans.rectValueToPixel(&_bodyRect)
                    let centerMidX = _bodyRect.midX
                    _bodyRect.origin.x = centerMidX - 2
                    _bodyRect.size.width = 4
                    
                    context.setFillColor(barColor.cgColor)
                    context.fill(_bodyRect)
                }
            
                // Draw top points
                let centerColor = dataSet.pointCenterColor ?? dataSet.color(atIndex: j)
                let strokeColor = dataSet.pointColor ?? dataSet.color(atIndex: j)
            
                // Draw open point
                var openPoint = CGRect()
                openPoint.origin.x = CGFloat(xPos) - 0.5 + barSpace
                openPoint.origin.y = CGFloat(close * phaseY)
                openPoint.size.width = (CGFloat(xPos) + 0.5 - barSpace) - openPoint.origin.x
                openPoint.size.height = CGFloat(open * phaseY) - openPoint.origin.y
                
                trans.rectValueToPixel(&openPoint)
                let midX = openPoint.midX
                openPoint.origin.x = midX - 2
                openPoint.size.width = 4
                openPoint.size.height = 4
                
                context.setFillColor(strokeColor.cgColor)
                context.setStrokeColor(strokeColor.cgColor)
                context.setLineWidth(2)
                context.addEllipse(in: openPoint)
                context.drawPath(using: .fillStroke)
                
                var centerPoint = CGRect()
                centerPoint.origin.x = CGFloat(xPos) - 0.5 + barSpace
                centerPoint.origin.y = CGFloat(close * phaseY)
                centerPoint.size.width = (CGFloat(xPos) + 0.5 - barSpace) - centerPoint.origin.x
                centerPoint.size.height = CGFloat(open * phaseY) - centerPoint.origin.y
                
                trans.rectValueToPixel(&centerPoint)
                let centerMidX = centerPoint.midX
                centerPoint.origin.x = centerMidX - 1
                centerPoint.origin.y = openPoint.origin.y + 1
                centerPoint.size.width = 2
                centerPoint.size.height = 2
                
                context.setFillColor(centerColor.cgColor)
                context.setStrokeColor(centerColor.cgColor)
                context.setLineWidth(2)
                context.addEllipse(in: centerPoint)
                context.drawPath(using: .fillStroke)

                // Draw bottom points
                if open != close {
                    var closePoint = CGRect()
                    closePoint.origin.x = CGFloat(xPos) - 0.5 + barSpace
                    closePoint.origin.y = CGFloat(close * phaseY)
                    closePoint.size.width = (CGFloat(xPos) + 0.5 - barSpace) - closePoint.origin.x
                    closePoint.size.height = CGFloat(open * phaseY) - closePoint.origin.y
                    
                    trans.rectValueToPixel(&closePoint)
                    let midX = closePoint.midX
                    closePoint.origin.x = midX - 2
                    closePoint.origin.y = closePoint.origin.y + closePoint.size.height
                    closePoint.size.width = 4
                    closePoint.size.height = 4
                    
                    context.setFillColor(strokeColor.cgColor)
                    context.setStrokeColor(strokeColor.cgColor)
                    context.setLineWidth(2)
                    context.addEllipse(in: closePoint)
                    context.drawPath(using: .fillStroke)
                    
                    var closeCenterPoint = CGRect()
                    closeCenterPoint.origin.x = CGFloat(xPos) - 0.5 + barSpace
                    closeCenterPoint.origin.y = CGFloat(close * phaseY)
                    closeCenterPoint.size.width = (CGFloat(xPos) + 0.5 - barSpace) - closeCenterPoint.origin.x
                    closeCenterPoint.size.height = CGFloat(open * phaseY) - closeCenterPoint.origin.y
                    
                    trans.rectValueToPixel(&closeCenterPoint)
                    let centerMidX = closeCenterPoint.midX
                    closeCenterPoint.origin.x = centerMidX - 1
                    closeCenterPoint.origin.y = closePoint.origin.y + 1
                    closeCenterPoint.size.width = 2
                    closeCenterPoint.size.height = 2
                    
                    context.setFillColor(centerColor.cgColor)
                    context.setStrokeColor(centerColor.cgColor)
                    context.setLineWidth(2)
                    context.addEllipse(in: closeCenterPoint)
                    context.drawPath(using: .fillStroke)
                }
            }
            else
            {
                _rangePoints[0].x = CGFloat(xPos)
                _rangePoints[0].y = CGFloat(high * phaseY)
                _rangePoints[1].x = CGFloat(xPos)
                _rangePoints[1].y = CGFloat(low * phaseY)

                _openPoints[0].x = CGFloat(xPos) - 0.5 + barSpace
                _openPoints[0].y = CGFloat(open * phaseY)
                _openPoints[1].x = CGFloat(xPos)
                _openPoints[1].y = CGFloat(open * phaseY)

                _closePoints[0].x = CGFloat(xPos) + 0.5 - barSpace
                _closePoints[0].y = CGFloat(close * phaseY)
                _closePoints[1].x = CGFloat(xPos)
                _closePoints[1].y = CGFloat(close * phaseY)
                
                trans.pointValuesToPixel(&_rangePoints)
                trans.pointValuesToPixel(&_openPoints)
                trans.pointValuesToPixel(&_closePoints)
                
                // draw the ranges
                var barColor: NSUIColor! = nil

                if open > close
                {
                    accessibilityMovementDescription = "decreasing"
                    barColor = dataSet.decreasingColor ?? dataSet.color(atIndex: j)
                }
                else if open < close
                {
                    accessibilityMovementDescription = "increasing"
                    barColor = dataSet.increasingColor ?? dataSet.color(atIndex: j)
                }
                else
                {
                    barColor = dataSet.neutralColor ?? dataSet.color(atIndex: j)
                }
                
                context.setStrokeColor(barColor.cgColor)
                context.strokeLineSegments(between: _rangePoints)
                context.strokeLineSegments(between: _openPoints)
                context.strokeLineSegments(between: _closePoints)
            }

            let axElement = createAccessibleElement(withIndex: j,
                                                    container: chart,
                                                    dataSet: dataSet)
            { (element) in
                element.accessibilityLabel = "\(doesContainMultipleDataSets ? "\(dataSet.label ?? "Dataset")" : "") " + "\(xPos) - \(accessibilityMovementDescription). low: \(low), high: \(high), opening: \(open), closing: \(close)"
                element.accessibilityFrame = accessibilityRect
            }

            accessibleChartElements.append(axElement)

        }

        // Post this notification to let VoiceOver account for the redrawn frames
        accessibilityPostLayoutChangedNotification()

        context.restoreGState()
    }
    
    open override func drawValues(context: CGContext)
    {
        guard
            let dataProvider = dataProvider,
            let candleData = dataProvider.candleData
            else { return }
        
        // if values are drawn
        if isDrawingValuesAllowed(dataProvider: dataProvider)
        {
            var dataSets = candleData.dataSets
            
            let phaseY = animator.phaseY
            
            var pt = CGPoint()
            
            for i in 0 ..< dataSets.count
            {
                guard let dataSet = dataSets[i] as? IBarLineScatterCandleBubbleChartDataSet
                    else { continue }
                
                if !shouldDrawValues(forDataSet: dataSet)
                {
                    continue
                }
                
                let valueFont = dataSet.valueFont
                
                guard let formatter = dataSet.valueFormatter else { continue }
                
                let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
                let valueToPixelMatrix = trans.valueToPixelMatrix
                
                let iconsOffset = dataSet.iconsOffset
                
                _xBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)
                
                let lineHeight = valueFont.lineHeight
                let yOffset: CGFloat = lineHeight + 5.0
                
                for j in stride(from: _xBounds.min, through: _xBounds.range + _xBounds.min, by: 1)
                {
                    guard let e = dataSet.entryForIndex(j) as? CandleChartDataEntry else { break }
                    
                    pt.x = CGFloat(e.x)
                    pt.y = CGFloat(e.high * phaseY)
                    pt = pt.applying(valueToPixelMatrix)
                    
                    if (!viewPortHandler.isInBoundsRight(pt.x))
                    {
                        break
                    }
                    
                    if (!viewPortHandler.isInBoundsLeft(pt.x) || !viewPortHandler.isInBoundsY(pt.y))
                    {
                        continue
                    }
                    
                    if dataSet.isDrawValuesEnabled
                    {
                        ChartUtils.drawText(
                            context: context,
                            text: formatter.stringForValue(
                                e.high,
                                entry: e,
                                dataSetIndex: i,
                                viewPortHandler: viewPortHandler),
                            point: CGPoint(
                                x: pt.x,
                                y: pt.y - yOffset),
                            align: .center,
                            attributes: [NSAttributedStringKey.font: valueFont, NSAttributedStringKey.foregroundColor: dataSet.valueTextColorAt(j)])
                    }
                    
                    if let icon = e.icon, dataSet.isDrawIconsEnabled
                    {
                        ChartUtils.drawImage(context: context,
                                             image: icon,
                                             x: pt.x + iconsOffset.x,
                                             y: pt.y + iconsOffset.y,
                                             size: icon.size)
                    }
                }
            }
        }
    }
    
    open override func drawExtras(context: CGContext)
    {
    }
    
    open override func drawHighlighted(context: CGContext, indices: [Highlight])
    {
        guard
            let dataProvider = dataProvider,
            let candleData = dataProvider.candleData
            else { return }
        
        context.saveGState()
        
        for high in indices
        {
            guard
                let set = candleData.getDataSetByIndex(high.dataSetIndex) as? ICandleChartDataSet,
                set.isHighlightEnabled
                else { continue }
            
            guard let e = set.entryForXValue(high.x, closestToY: high.y) as? CandleChartDataEntry else { continue }
            
            if !isInBoundsX(entry: e, dataSet: set)
            {
                continue
            }
            
            let trans = dataProvider.getTransformer(forAxis: set.axisDependency)
            
            context.setStrokeColor(set.highlightColor.cgColor)
            context.setLineWidth(set.highlightLineWidth)
            
            if set.highlightLineDashLengths != nil
            {
                context.setLineDash(phase: set.highlightLineDashPhase, lengths: set.highlightLineDashLengths!)
            }
            else
            {
                context.setLineDash(phase: 0.0, lengths: [])
            }
            
            let lowValue = e.low * Double(animator.phaseY)
            let highValue = e.high * Double(animator.phaseY)
            let y = (lowValue + highValue) / 2.0
            
            let pt = trans.pixelForValues(x: e.x, y: y)
            
            high.setDraw(pt: pt)
            
            // draw the lines
            drawHighlightLines(context: context, point: pt, set: set)
        }
        
        context.restoreGState()
    }

    private func createAccessibleElement(withIndex idx: Int,
                                         container: CandleChartDataProvider,
                                         dataSet: ICandleChartDataSet,
                                         modifier: (NSUIAccessibilityElement) -> ()) -> NSUIAccessibilityElement {

        let element = NSUIAccessibilityElement(accessibilityContainer: container)

        // The modifier allows changing of traits and frame depending on highlight, rotation, etc
        modifier(element)

        return element
    }
}
