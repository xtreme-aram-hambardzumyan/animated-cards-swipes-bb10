import bb.cascades 1.0

Page {
    property int cardHeight: 460
    property int cardWidth: 730
    property int verticalShift: 70
    property int padding: 20
    property variant colours: []
    property int stickThresholdX: 40
    property int swipeThresholdX: 180
    property int stickThresholdY: 40
    property int swipeThresholdY: 60
    property bool cardAnimating
    property double maxDragTilt: 10
    property double maxAnimationTilt: 15

	Container {
	    id: cardContainer
	    leftPadding: padding
        rightPadding: padding
    	topPadding: 350
        horizontalAlignment: HorizontalAlignment.Center
    	property int bottomVisibleCount: 2 //number of item at the bottom of stack that are still partially visible 
    	property int topVisibleCount: 3 //number of item at the bottom of stack that are visible (including topmost item)
        property double moveStartPositionX: -1
        property double currentMovePositionX: -1
        property double moveStartPositionY: -1
    	property double currentMovePositionY: -1
    	property int topItemOffset
    	property int rotationDirection

        layout: AbsoluteLayout {}

        function rearrange() {
            remove(condensedCardsMarker)

            var offset = topPadding
            var itemCount = count()
            for(var i = 0; i < itemCount; ++i) {
                var item = at(i)
                item.offset = offset
                if(i < bottomVisibleCount || i >= itemCount - topVisibleCount) {
                    offset += verticalShift
                } else if (i == bottomVisibleCount && i < itemCount - topVisibleCount) {
                    offset += condensedCardsMarker.height
                }
            }

            insert(bottomVisibleCount + 1, condensedCardsMarker)
        }

        function rotate() {
            var item = getTopmostItem()
            remove(item)
            insert(0, item)
            rearrange()
        }

        function getTopmostItem() {
            return at(count() - 1)
        }

        function itemTouched(item, event) {
            if(item == getTopmostItem()) {
                topItemSwiped(event)
            } else {
                bottomItemTouched(item, event)
            }
        }

        function topItemSwiped(event) {
            var topmostItem = getTopmostItem()
            switch (event.touchType) {
                case TouchType.Down: {
                    moveStartPositionX = event.windowX
                    currentMovePositionX = event.windowX
                    moveStartPositionY = event.windowY
                    currentMovePositionY = event.windowY
                }
                break
                case TouchType.Move: {
                    currentMovePositionX = event.windowX

                    var horizShift = currentMovePositionX - moveStartPositionX
                    var absHorizShift = Math.abs(horizShift)
                    var vertShift = event.windowY - moveStartPositionY
                    var absVertShift = Math.abs(vertShift)

                    if (-vertShift > stickThresholdY) {
                        topmostItem.translationX = horizShift
                        topmostItem.translationY = vertShift

                        rotationDirection = horizShift / absHorizShift
                        topmostItem.pivotX = rotationDirection > 0 ? cardWidth : 0
                        if(absHorizShift > stickThresholdX) {
                            var screenWidth = 768
                            var tiltingStartX = moveStartPositionX + rotationDirection * stickThresholdX
                            var k = maxDragTilt / ((rotationDirection > 0 ? screenWidth : 0) - tiltingStartX)
                        	topmostItem.rotationZ = k * (absHorizShift - stickThresholdX)
                        	//topmostItem.opacity = .4
                    	}

                        if (event.windowY < currentMovePositionY) {
                            currentMovePositionY = event.windowY
                        }
                    }
                }
                break
                case TouchType.Cancel:
                case TouchType.Up: {
                    if (currentMovePositionY >= 0
                            && (event.windowY - currentMovePositionY < 20 || Math.abs(event.windowX - moveStartPositionX) > swipeThresholdX)
                            && moveStartPositionY - currentMovePositionY > swipeThresholdY) {
                        cardAnimating = true
                        removalPhase.target = topmostItem
                        removalPhase.play()
                    } else {
                        topmostItem.rotationZ = 0
                        topmostItem.translationX = 0
                        topmostItem.translationY = 0
                        topmostItem.opacity = 1
                    }

                    moveStartPositionX = -1
                    currentMovePositionX = -1
                    moveStartPositionY = -1
                    currentMovePositionY = -1
                }
                break
            }
        }

        function bottomItemTouched(item, event) {
            if(TouchType.Up == event.touchType) {
            	cardAnimating = true
            	itemPuller.target = item
            	itemPuller.play()
            }
        }

        onCreationCompleted: {
		    var clrs = colours
            for (var r = 0; r <= .5; r += .4) for (var g = 0; g <= 1; g += .4) for (var b = 0; b <= 1; b += .4) {
                clrs.push(Color.create(r, g, b))
            }
            colours = clrs

            var i = 0
        	for(; i < colours.length; ++i) {
                var item = itemPrototype.createObject()
                item.index = i
                add(item)
            }

            rearrange()

            topItemOffset = getTopmostItem().offset
        }

		attachedObjects: [
		    ComponentDefinition {
		        id: itemPrototype
            	Container {
            	    id: thisItem
            	    layout: DockLayout { }

		            layoutProperties: AbsoluteLayoutProperties {
		                positionY: offset
		            }

		            horizontalAlignment: HorizontalAlignment.Center
                    preferredHeight: cardHeight
		            preferredWidth: cardWidth
		            background: colours[index]
		            pivotY: cardHeight
            	    property int index
            	    property int offset

		            Divider {
                    	topMargin: 2
                    	bottomMargin: 0
                    }
		            Label {
                    	text: index + 1
                    	horizontalAlignment: HorizontalAlignment.Center
                    	topMargin: 0
                    	textStyle {
                    	    fontSize: FontSize.XXSmall
                    	    color: Color.White
                    	}
                    }
                    onTouch: {
		                if(cardAnimating)
		                	return

                    	cardContainer.itemTouched(thisItem, event)
                    }
                }
            },
            ParallelAnimation {
                id: removalPhase
                property int duration: 450
                animations: [
                    RotateTransition {
                    	toAngleZ: cardContainer.rotationDirection * maxAnimationTilt
                        duration: removalPhase.duration
                    },
				    TranslateTransition {
				        id: moveUp
				        toX: removalPhase.target ? removalPhase.target.translationX + cardContainer.rotationDirection * cardWidth * .25 : 0
				        toY: removalPhase.target ? -removalPhase.target.offset - verticalShift : 0
                        duration: removalPhase.duration
			        },
                    FadeTransition {
                    	toOpacity: 0
                    	delay: 50
                        duration: removalPhase.duration
                    }
            	]
                onEnded: {
                    cardContainer.rotate()
                    target.translationX = 0
                    target.translationY = 0
                    target.rotationZ = 0

                    insertionPhase.target = target
                    insertionPhase.play()
                }
            },
		    FadeTransition {
		        id: insertionPhase
		        toOpacity: 1
		        duration: 350
		        onEnded: {
                    cardAnimating = false
                }
		    },
		    TranslateTransition {
            	id: itemPuller
                toX: 0
                toY: -cardHeight
                duration: 250
                onEnded: {
                    cardContainer.remove(target)
                    cardContainer.add(target)

                    itemMover.target = target
                    itemMover.play()
                }
            },
            TranslateTransition {
                id: itemMover
                toX: 0
                toY: itemPuller.toY + cardContainer.topItemOffset
                duration: 350
                onEnded: {
                    cardContainer.rearrange()
                    target.translationX = 0
                    target.translationY = 0
                    cardAnimating = false
                }
            },
            Container {
                id: condensedCardsMarker
                layoutProperties: AbsoluteLayoutProperties {
                    positionY: condensedCardsMarker.offset
                }

                horizontalAlignment: HorizontalAlignment.Center
                preferredWidth: cardWidth
                property int height: marker.lineHeight * marker.count() + marker.bottomPadding
                property int offset: cardContainer.topPadding + cardContainer.bottomVisibleCount * verticalShift

                Container {
                    id: marker
                    background: Color.Gray
                    bottomPadding: 5
                    property int lineHeight: 3

                    Divider {
                        topMargin: marker.lineHeight
                        bottomMargin: 0
                    }
                    Divider {
                        topMargin: marker.lineHeight
                        bottomMargin: 0
                    }
                    Divider {
                        topMargin: marker.lineHeight
                        bottomMargin: 0
                    }
                }
            }
        ]
    }
}
