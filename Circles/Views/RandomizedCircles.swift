//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  RandomizedCircles.swift
//  Circles for iOS
//
//  Created by Charles Wright on 1/26/21.
//

import SwiftUI

struct CircleParameters {
    @Environment(\.colorScheme) var colorScheme

    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var fillColor: Color
    //var outlineColor: Color
    
    
    init(x: CGFloat, y: CGFloat, scale: CGFloat) {
        self.x = x
        self.y = y
        //self.scale = scale * CGFloat(Double.random(in: 0.6 ..< 1.2))
        self.scale = scale
        
        let colors = [Color.green, Color.purple, Color.yellow, Color.orange, Color.red, .pink, Color.green, Color.orange]

        self.fillColor = colors.randomElement() ?? Color.green
    }
    
    var outlineColor: Color {
        colorScheme == .dark
            ? .white
            : .black
    }
}

struct RandomizedCircles: View {
    @Environment(\.colorScheme) var colorScheme

    
    let scale: CGFloat = 0.40
    let n: Int = 9
    let colors = [Color.green, Color.purple, Color.yellow, Color.orange, Color.red, .pink, Color.green, Color.orange]
    
    func makeParams(cX: CGFloat, cY: CGFloat, radius: CGFloat) -> [CircleParameters] {
        var params: [CircleParameters] = []
        for i in 0 ..< n {
            let fraction: Double = Double(i) / Double(n)
            let angle = Angle(degrees: 360 * fraction + 27)
            let radians = CGFloat(angle.radians)

            let rand = CGFloat(Double.random(in: 0.3 ..< 1.05))
            let offset = (1.0 + 0.45 * rand) * radius
            let x = cX + cos(radians) * offset
            let y = cY + sin(radians) * offset
            
            let p = CircleParameters(x: x,
                                     y: y,
                                     scale: 0.75 * rand * self.scale)
            params.append(p)
        }
        return params
    }
    
    var body: some View {
        GeometryReader { geometry in
            let len = min(geometry.size.height, geometry.size.width)
            let radius = scale * len * 0.5
            let offset = 1.0 * radius
            let xCenter = 0.50 * geometry.size.width
            let yCenter = 0.50 * geometry.size.height
            let outlineColor: Color = colorScheme == .dark ? .white : .black

            let parameters = self.makeParams(cX: xCenter, cY: yCenter, radius: radius)


            // At the very bottom - The fill for the big circle in the middle
            Circle()
                .foregroundColor(Color.accentColor.opacity(0.95))
                .position(x: xCenter,
                          y: yCenter)
                .scaleEffect(scale)
            
            // Then the fill for each of the periphery circles
            ForEach(0 ..< n) { i in
                let params = parameters[i]
                
                Circle()
                    .fill(params.fillColor.opacity(0.55))
                    .scaleEffect(params.scale)
                    .position(x: params.x, y: params.y)
            }
            
            // Next the outline for the periphery circles
            ForEach(0 ..< n) { i in
                let params = parameters[i]
                
                Circle()
                    .stroke(outlineColor, lineWidth: 10.0)
                    .scaleEffect(params.scale)
                    .position(x: params.x, y: params.y)
            }
            
            // Finally the outline for the big circle in the middle
            Circle()
                .stroke(outlineColor, lineWidth: 12.5)
                .position(x: xCenter,
                          y: yCenter)
                .scaleEffect(scale)
        }
    }
}

struct Badge_Previews: PreviewProvider {
    static var previews: some View {
        RandomizedCircles()
    }
}
