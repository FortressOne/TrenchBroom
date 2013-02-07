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

#include "MoveTool.h"

#include "Controller/Command.h"
#include "Model/Picker.h"
#include "Renderer/MovementIndicator.h"
#include "Renderer/RenderContext.h"
#include "Utility/Grid.h"

namespace TrenchBroom {
    namespace Controller {
        void MoveTool::handleRender(InputState& inputState, Renderer::Vbo& vbo, Renderer::RenderContext& renderContext) {
            if ((inputState.mouseButtons() != MouseButtons::MBNone &&
                 inputState.mouseButtons() != MouseButtons::MBLeft) ||
                (inputState.modifierKeys() != ModifierKeys::MKNone &&
                 inputState.modifierKeys() != ModifierKeys::MKAlt))
                return;
            
            Vec3f hitPoint;
            if (!isApplicable(inputState, hitPoint))
                return;
            
            if (m_indicator == NULL)
                m_indicator = new Renderer::MovementIndicator();
            
            if (dragType() == DTDrag) {
                if (m_direction == LeftRight)
                    m_indicator->setDirection(Renderer::MovementIndicator::LeftRight);
                else if (m_direction == Horizontal)
                    m_indicator->setDirection(Renderer::MovementIndicator::Horizontal);
                else
                    m_indicator->setDirection(Renderer::MovementIndicator::Vertical);
            } else {
                if (inputState.modifierKeys() == ModifierKeys::MKAlt) {
                    m_indicator->setDirection(Renderer::MovementIndicator::Vertical);
                } else {
                    if (std::abs(inputState.pickRay().direction.z) < 0.2f)
                        m_indicator->setDirection(Renderer::MovementIndicator::LeftRight);
                    else
                        m_indicator->setDirection(Renderer::MovementIndicator::Horizontal);
                }
            }
            
            Vec3f position = renderContext.camera().defaultPoint(inputState.x() + 20.0f, inputState.y() + 20.0f);
            m_indicator->setPosition(position);
            m_indicator->render(vbo, renderContext);
        }
        
        void MoveTool::handleFreeRenderResources() {
            delete m_indicator;
            m_indicator = NULL;
        }
        
        void MoveTool::handleModifierKeyChange(InputState& inputState) {
            if (dragType() != DTDrag)
                return;
            
            resetPlane(inputState);
        }
        
        bool MoveTool::handleStartPlaneDrag(InputState& inputState, Plane& plane, Vec3f& initialPoint) {
            if (inputState.mouseButtons() != MouseButtons::MBLeft ||
                (inputState.modifierKeys() != ModifierKeys::MKNone &&
                 inputState.modifierKeys() != ModifierKeys::MKAlt))
                return false;

            if (!isApplicable(inputState, initialPoint))
                return false;
            
            m_totalDelta = Vec3f::Null;
            
            if (inputState.modifierKeys() == ModifierKeys::MKAlt) {
                Vec3f planeNorm = inputState.pickRay().direction;
                planeNorm.z = 0.0f;
                planeNorm.normalize();
                
                if (planeNorm.null())
                    return false;
                
                plane = Plane(planeNorm, initialPoint);
                m_direction = Vertical;
            } else {
                if (std::abs(inputState.pickRay().direction.z) < 0.2f) {
                    plane = Plane::verticalDragPlane(initialPoint, inputState.camera().direction());
                    m_direction = LeftRight;
                } else {
                    plane = Plane::horizontalDragPlane(initialPoint);
                    m_direction = Horizontal;
                }
            }
            
            beginCommandGroup(actionName());
            
            return true;
        }
        
        void MoveTool::handleResetPlane(InputState& inputState, Plane& plane, Vec3f& initialPoint) {
            float distance = plane.intersectWithRay(inputState.pickRay());
            if (Math::isnan(distance))
                return;
            initialPoint = inputState.pickRay().pointAtDistance(distance);
            
            if (inputState.modifierKeys() == ModifierKeys::MKAlt) {
                Vec3f planeNorm = inputState.pickRay().direction;
                planeNorm.z = 0.0f;
                planeNorm.normalize();
                
                plane = Plane(planeNorm, initialPoint);
                m_direction = Vertical;
            } else {
                if (std::abs(inputState.pickRay().direction.z) < 0.2f) {
                    plane = Plane::verticalDragPlane(initialPoint, inputState.camera().direction());
                    m_direction = LeftRight;
                } else {
                    plane = Plane::horizontalDragPlane(initialPoint);
                    m_direction = Horizontal;
                }
            }
        }
        
        bool MoveTool::handlePlaneDrag(InputState& inputState, const Vec3f& lastPoint, const Vec3f& curPoint, Vec3f& refPoint) {
            Vec3f delta = curPoint - refPoint;
            if (m_direction == Vertical) {
                delta = Vec3f::PosZ * delta.dot(Vec3f::PosZ);
            } else if (m_direction == LeftRight) {
                Vec3f axis = Vec3f::PosZ.crossed(dragPlane().normal);
                delta = axis * delta.dot(axis);
            }
            
            Utility::Grid& grid = document().grid();
            delta = grid.snap(delta);
            if (delta.null())
                return true;
            
            MoveResult result = performMove(delta);
            if (result == Conclude)
                return false;
            
            if (result == Continue) {
                refPoint += delta;
                m_totalDelta += delta;
            }
            
            return true;
        }
        
        void MoveTool::handleEndPlaneDrag(InputState& inputState) {
            if (m_totalDelta.null())
                discardCommandGroup();
            else
                endCommandGroup();
        }

        MoveTool::MoveTool(View::DocumentViewHolder& documentViewHolder, InputController& inputController, bool activatable) :
        PlaneDragTool(documentViewHolder, inputController, activatable),
        m_indicator(NULL) {}
    }
}