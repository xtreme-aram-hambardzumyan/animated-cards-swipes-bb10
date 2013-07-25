import bb.cascades 1.0

Page {
    property int cardHeight: 250
    property int cardWidth: 700
    property int verticalShift: 70
    property int padding: 20
    property variant colours: []
    property int hoirzStickyTreshold: 40
    property int horizSwipeTreshold: 150
    property int vertSwipeTreshold: 60
    property variant grabbedItem

    Container {
        layout: DockLayout { }

	    Container {
		    horizontalAlignment: HorizontalAlignment.Center
		    verticalAlignment: VerticalAlignment.Center

			Container {
			    id: cardContainer
			    leftPadding: padding
	            rightPadding: padding
	        	topPadding: cardHeight + 50
	            horizontalAlignment: HorizontalAlignment.Center
	        	property int lowestPosition: 100
	        	property int bottomVisibleCount: 2 //number of item at the bottom of stack that are still partially visible 
	        	property int topVisibleCount: 3 //number of item at the bottom of stack that are visible (including topmost item)
                property double moveStartPositionX: -1
                property double currentMovePositionX: -1
                property double moveStartPositionY: -1
	        	property double currentMovePositionY: -1
	        	property string swipeDirection
	        	property int topItemOffset

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
                    if(grabbedItem && item != grabbedItem)
                    	return

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
                            moveStartPositionX = event.localX
                            currentMovePositionX = event.localX
                            moveStartPositionY = event.localY
                            currentMovePositionY = event.localY
                        }
                        break
                        case TouchType.Move: {
                            currentMovePositionX = event.localX

                            var horizShift = currentMovePositionX - moveStartPositionX
                            var absHorizShift = Math.abs(horizShift)

                            if (absHorizShift > hoirzStickyTreshold && swipeDirection != 'v' || absHorizShift > hoirzStickyTreshold * 2) { //even if the user had started vertical swipe, if the finger has moved too much to the side, it's more natural to switch to horizontal swipe:
                                topmostItem.translationX = horizShift
                                swipeDirection = 'h'

                                if (absHorizShift > horizSwipeTreshold) {
                                    var sign = horizShift / absHorizShift
                                    topmostItem.rotationZ = sign * Math.min((absHorizShift - horizSwipeTreshold) * .15, 15)
                                    topmostItem.opacity = .4
                                }
                            } else if (currentMovePositionY >= 0 && swipeDirection != 'h') {
                                topmostItem.translationY = Math.min(event.localY - moveStartPositionY, 0)

								//console.log('last pos: ' + currentMovePositionY + ', new pos: ' + event.localY)
                                if (event.localY < currentMovePositionY) {
                                    //console.log('moving vertically')
                                    currentMovePositionY = event.localY
                                    swipeDirection = 'v'
                                } else if (event.localY > currentMovePositionY) {
                                    //console.log('ignoring move')
                                    swipeDirection = ''
                                }
                            }
                        }
                        break
                        case TouchType.Cancel:
                        case TouchType.Up: {
//                            console.log(swipeDirection)
                            if (swipeDirection == 'v' && currentMovePositionY >= 0 && event.localY < currentMovePositionY && moveStartPositionY - currentMovePositionY > vertSwipeTreshold) {
                                topToBackFipper.target = topmostItem
                                topToBackFipper.play()
                            } else if (swipeDirection = 'h' && Math.abs(topmostItem.translationX) > horizSwipeTreshold) {
                                rotatingFlipper.target = topmostItem
                                rotatingFlipper.play()
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
                            swipeDirection = ''
                        }
                        break
                    }
                }

                function bottomItemTouched(item, event) {
                    if(TouchType.Up == event.touchType) {
//                        midItemPicker.target = item
//                        midItemPicker.play()
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

				            layoutProperties: AbsoluteLayoutProperties {
				                positionY: offset
				            }

				            horizontalAlignment: HorizontalAlignment.Center
                            preferredHeight: cardHeight
				            preferredWidth: cardWidth
				            background: colours[index]
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
				                if(!grabbedItem)
                                	grabbedItem = thisItem
                                if(grabbedItem == thisItem)
                                	cardContainer.itemTouched(thisItem, event)
                            }
	                    }
	                },
				    SequentialAnimation {
				        id: topToBackFipper
	                    animations: [
						    TranslateTransition {
						        id: moveUp
						        toX: 0
						        toY: topToBackFipper.target ? -topToBackFipper.target.offset : 0
	                            duration: 250
					        },
						    TranslateTransition {
						        toX: 0
						        toY: moveUp.toY + cardHeight - verticalShift
						        duration: 180
			                }
				        ]
				        onEnded: {
				            cardContainer.rotate()
				            target.translationX = 0
				            target.translationY = 0
                            grabbedItem = null
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
                        duration: 250
                        onEnded: {
                            cardContainer.rearrange()
                            target.translationX = 0
                            target.translationY = 0
                            grabbedItem = null
                        }
                    },
                    SequentialAnimation {
                    	id: rotatingFlipper
                    	animations: [
                    	    FadeTransition {
                            	toOpacity: .8
                            	duration: 60
                            },
						    ParallelAnimation {
		                    	id: rotationPhase
		                    	property int duration: 400
		                    	animations: [
		                    	    RotateTransition {
		                            	toAngleZ: 0
		                                duration: rotationPhase.duration
		                            },
		                    	    FadeTransition {
		                            	toOpacity: 1
		                                duration: rotationPhase.duration
		                            },
		                            TranslateTransition {
		                                toX: 0
		                                toY: rotatingFlipper.target ? -rotatingFlipper.target.offset + cardHeight - verticalShift : 0
		                                duration: rotationPhase.duration
		                            }
		                        ]
		                    }
                        ]
                        onEnded: {
                            cardContainer.rotate()
                            target.translationX = 0
                            target.translationY = 0
                            grabbedItem = null
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
    }
}
