/*
 Copyright (C) 2010-2012 Kristian Duske
 
 This file is part of TrenchBroom.
 
 TrenchBroom is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 TrenchBroom is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with TrenchBroom.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "Preferences.h"

namespace TrenchBroom {
    namespace Model {
        const string Preferences::CameraKey                         = "Controls: camera key";
        const string Preferences::CameraOrbitKey                    = "Controls: camera orbit key";
        const string Preferences::FaceColor                         = "Renderer: face color";
        const string Preferences::EdgeColor                         = "Renderer: edge color";
        const string Preferences::SelectedFaceColor                 = "Renderer: face color (selected)";
        const string Preferences::SelectedEdgeColor                 = "Renderer: edge color (selected)";
        const string Preferences::HiddenSelectedEdgeColor           = "Renderer: edge color (selected and hidden)";
        const string Preferences::EntityBoundsColor                 = "Renderer: entity bounds color";
        const string Preferences::EntityBoundsWireframeColor        = "Renderer: entity bounds color (wireframe mode)";
        const string Preferences::SelectedEntityBoundsColor         = "Renderer: entity bounds color (selected)";
        const string Preferences::HiddenSelectedEntityBoundsColor   = "Renderer: entity bounds color (selected and hidden)";
        const string Preferences::SelectionGuideColor               = "Renderer: selection guide color";
        const string Preferences::HiddenSelectionGuideColor         = "Renderer: selection guide color (hidden)";
        const string Preferences::BackgroundColor                   = "Renderer: background color";
        const string Preferences::InfoOverlayColor                  = "Renderer: info overlay color";
        const string Preferences::InfoOverlayFadeDistance           = "Renderer: info overlay fade distance";
        const string Preferences::SelectedInfoOverlayColor          = "Renderer: info overlay color (selected)";
        const string Preferences::SelectedInfoOverlayFadeDistance   = "Renderer: info overlay fade distance (selected)";
        const string Preferences::RendererFontName                  = "Renderer: font name";
        const string Preferences::RendererFontSize                  = "Renderer: font size";
        const string Preferences::GridAlpha                         = "Renderer: grid translucency";
        const string Preferences::QuakePath                         = "General: quake path";
        
        void Preferences::loadDefaults() {
            m_faceColor = Vec4f(0.2f, 0.2f, 0.2f, 1);
            m_edgeColor = Vec4f(0.6f, 0.6f, 0.6f, 0.6f);
            m_selectedFaceColor = Vec4f(0.6f, 0.35f, 0.35f, 1);
            m_selectedEdgeColor = Vec4f(1, 0, 0, 1);
            m_hiddenSelectedEdgeColor = Vec4f(1, 0, 0, 0.35f);
            m_entityBoundsColor = Vec4f(0.5f, 0.5f, 0.5f, 1);
            m_entityBoundsWireframeColor = Vec4f(0.5f, 0.5f, 0.5f, 0.6f);
            m_selectedEntityBoundsColor = m_selectedEdgeColor;
            m_hiddenSelectedEntityBoundsColor = m_hiddenSelectedEdgeColor;
            m_selectionGuideColor = m_selectedEdgeColor;
            m_hiddenSelectionGuideColor = m_hiddenSelectedEdgeColor;
            m_backgroundColor = Vec4f(0, 0, 0, 0);
            
            m_infoOverlayColor= Vec4f(1, 1, 1, 1);
            m_infoOverlayFadeDistance = 400;
            m_selectedInfoOverlayColor = Vec4f(1, 0, 0, 1);
            m_selectedInfoOverlayFadeDistance = 2000;
            
            m_rendererFontName = "Helvetica";
            m_rendererFontSize = 11;
            
            m_gridAlpha = 0.15f;
            
            m_quakePath = "";
            
            loadPlatformDefaults();
        }
        
        Preferences* Preferences::sharedPreferences = NULL;

        void Preferences::init() {
            loadDefaults();
            loadPlatformDefaults();
            loadPreferences();
        }
        
        int Preferences::cameraKey() {
            return m_cameraKey;
        }
        
        int Preferences::cameraOrbitKey() {
            return m_cameraOrbitKey;
        }

        float Preferences::cameraFov() {
            return 90;
        }
        
        float Preferences::cameraNear() {
            return 10;
        }
        
        float Preferences::cameraFar() {
            return 10000;
        }

        float Preferences::brightness() {
            return 1;
        }

        const Vec4f& Preferences::faceColor() {
            return m_faceColor;
        }
        
        const Vec4f& Preferences::edgeColor(){
            return m_edgeColor;
        }
        
        const Vec4f& Preferences::selectedFaceColor() {
            return m_selectedFaceColor;
        }
        
        const Vec4f& Preferences::selectedEdgeColor() {
            return m_selectedEdgeColor;
        }
        
        const Vec4f& Preferences::hiddenSelectedEdgeColor() {
            return m_hiddenSelectedEdgeColor;
        }
        
        const Vec4f& Preferences::entityBoundsColor() {
            return m_entityBoundsColor;
        }
        
        const Vec4f& Preferences::entityBoundsWireframeColor() {
            return m_entityBoundsWireframeColor;
        }

        const Vec4f& Preferences::selectedEntityBoundsColor() {
            return m_selectedEntityBoundsColor;
        }
        
        const Vec4f& Preferences::hiddenSelectedEntityBoundsColor() {
            return m_hiddenSelectedEntityBoundsColor;
        }

        const Vec4f& Preferences::selectionGuideColor() {
            return m_selectionGuideColor;
        }
        const Vec4f& Preferences::hiddenSelectionGuideColor() {
            return m_hiddenSelectionGuideColor;
        }

        const Vec4f& Preferences::backgroundColor() {
            return m_backgroundColor;
        }

        const Vec4f& Preferences::infoOverlayColor() {
            return m_infoOverlayColor;
        }
        
        float Preferences::infoOverlayFadeDistance() {
            return m_infoOverlayFadeDistance;
        }
        
        const Vec4f& Preferences::selectedInfoOverlayColor() {
            return m_selectedInfoOverlayColor;
        }
        
        float Preferences::selectedInfoOverlayFadeDistance() {
            return m_selectedInfoOverlayFadeDistance;
        }

        const string& Preferences::rendererFontName() {
            return m_rendererFontName;
        }
        
        int Preferences::rendererFontSize() {
            return m_rendererFontSize;
        }

        float Preferences::gridAlpha() {
            return m_gridAlpha;
        }

        const string& Preferences::quakePath() {
            return m_quakePath;
        }
    }
}