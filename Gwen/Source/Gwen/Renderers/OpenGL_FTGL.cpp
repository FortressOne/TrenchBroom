/*
 GWEN
 Copyright (c) 2012 Kristian Duske
 See license in Gwen.h
 */

#include "OpenGL_FTGL.h"
#include "Gwen/Platform.h"
#include "GL/GLee.h"
#include <string>
#include <fstream>

namespace Gwen {
    namespace Renderer {
        bool operator<(FontDescriptor const& left, FontDescriptor const& right) {
            int cmp = left.name.compare(right.name);
            if (cmp < 0) return true;
            if (cmp > 0) return false;
            return left.size < right.size;
        }

        OpenGL_FTGL::OpenGL_FTGL() {}
        
        OpenGL_FTGL::~OpenGL_FTGL() {}
        
        FontPtr OpenGL_FTGL::loadFont(Gwen::Font* pFont) {
            FontDescriptor descriptor(pFont->facename, pFont->size);
            FontCache::iterator it = m_fontCache.find(descriptor);
            if (it == m_fontCache.end()) {
                String fontPath = Gwen::Platform::ResolveFontPath(pFont);
                FTFont* font = new FTPixmapFont(fontPath.c_str());
                FontPtr fontPtr(font);
                fontPtr->FaceSize(static_cast<int>(pFont->size));
                m_fontCache[descriptor] = fontPtr;
                return fontPtr;
            } else {
                return it->second;
            }
        }

        void OpenGL_FTGL::RenderText( Gwen::Font* pFont, Gwen::Point pos, const Gwen::UnicodeString& text ) {
            FontPtr renderFont = loadFont(pFont);
			Gwen::String convertedText = Gwen::Utility::UnicodeToString( text );
            
            FTBBox bounds = renderFont->BBox("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz");
            int height = static_cast<int>(ceilf(bounds.Upper().Yf()));

            glRasterPos2f(pos.x + m_RenderOffset.x - 1, pos.y + m_RenderOffset.y + height);
            renderFont->Render(convertedText.c_str());
        }
        
        Gwen::Point OpenGL_FTGL::MeasureText( Gwen::Font* pFont, const Gwen::UnicodeString& text ) {
            FontPtr renderFont = loadFont(pFont);
			Gwen::String convertedText = Gwen::Utility::UnicodeToString( text );

            FTBBox lBounds = renderFont->BBox(convertedText.c_str());
            FTBBox hBounds = renderFont->BBox("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz");
            int length = static_cast<int>(ceilf(lBounds.Upper().Xf() - lBounds.Lower().Xf()));
            int height = static_cast<int>(ceilf(hBounds.Upper().Yf() - hBounds.Lower().Yf()));
            
            return Gwen::Point(length, height);
        }
    }
}