extends Node2D
#takes the texture attached to Sprite and estimates how many rows and columns
#of sprites are contained in the sheet
#proof of conecept so not optimized at all, there are serious improvements
#that can be made here

#included spritesheets are CC0 from Kenney ( https://kenney.nl/assets )
# who is very kind for providing these

onready var spriteSheet= $Sprite

onready var sheetSize = spriteSheet.texture.get_size();

onready var pxWidth: int =sheetSize.x
onready var pxHeight: int =sheetSize.y

var lowFrameCountPenalty=0.1; #deprioritizes lower framecounts compared to higher ones

# Called when the node enters the scene tree for the first time.
func _ready():
	var potentialWidths=[0]
	var potentialHeights=[0]
	potentialWidths.resize(128)
	potentialHeights.resize(128)
	potentialWidths.fill(0)
	potentialHeights.fill(0)
	
	#
	var columnsum = [0]
	var rowsum = [0]
	columnsum.resize(pxWidth);
	rowsum.resize(pxHeight);
	columnsum.fill(0)
	rowsum.fill(0)
	

	
	# this is quick and dirty proof of concept code
	# and if you have more than 128 frames in your sprite sheet you have a serious problem.
	var maxXFrameNumber=min(128,floor(sqrt(pxWidth)));
	var maxYFrameNumber=min(128,floor(sqrt(pxHeight)));
	
	var potentialXFrames=[0]
	var potentialYFrames=[0]
	potentialXFrames.resize(maxXFrameNumber+1)
	potentialYFrames.resize(maxYFrameNumber+1)
	potentialXFrames.fill(0)
	potentialYFrames.fill(0)
	
	var sheetImage=spriteSheet.texture.get_data()
	#I'm sure there's a more clever and efficient low-level way to do this
	#but screw it, pixel-by-pixel it is!
	sheetImage.lock()
	for xindex in range (0,pxWidth-1):
		for yindex in range(0,pxHeight-1):
			var myPix=sheetImage.get_pixel(xindex,yindex)	
			columnsum[xindex]= columnsum[xindex]+1-myPix.a # switch alpha values around so we are measuring transparency
			rowsum[yindex]= rowsum[yindex]+1-myPix.a # switch alpha values around so we are measuring transparency
	sheetImage.unlock()
	

		
		
		#check for an alpha channel
	if (columnsum.max()==columnsum.min()):
		print('file has no alpha variation')
	else:


		
		#handle the single frame case
		potentialXFrames[1]=waitDoesGodotSERIOUSLYNotHaveANativeMeanOrSumFunctionForArraysWTF(columnsum)*(1-lowFrameCountPenalty);
		for index in range( 2,maxXFrameNumber):
			if (pxWidth%index==0):
				for midFrameIndex in range(1,index):
					#we assume that the left and right edges of the frame
					#should have the least alpha
					#left side, counting up
					potentialXFrames[index] =potentialXFrames[index] + columnsum[ (midFrameIndex-1) * pxWidth/index];
					#right side, counting down
					potentialXFrames[index] = potentialXFrames[index] + columnsum[columnsum.size()-1 - (midFrameIndex-1) * pxWidth/index];
					
					
					#we will assume that the middle of the frame should have
					#the most alpha!  Subtract it
					potentialXFrames[index] =potentialXFrames[index] - columnsum[ ceil(pxWidth/(index*2)) + (midFrameIndex-1) * pxWidth/index];
				
				#make this an average
				potentialXFrames[index]=potentialXFrames[index]/index;
				#prioritize more frames over fewer (slightly)
				potentialXFrames[index]=potentialXFrames[index]*(index-lowFrameCountPenalty)/index;
			
		

		#handle the single frame case
		potentialYFrames[1]=waitDoesGodotSERIOUSLYNotHaveANativeMeanOrSumFunctionForArraysWTF(rowsum)*(1-lowFrameCountPenalty);
		for index in range( 2,maxYFrameNumber):
			if ( pxHeight%index ==0):
				for midFrameIndex in range(1,index):
					#we assume that the top and bottom edges of the frame
					#should have the least alpha
					#top side, counting up
					potentialYFrames[index] =potentialYFrames[index] + rowsum[ (midFrameIndex-1) * pxHeight/index];
					#bottom side, counting down
					potentialYFrames[index] = potentialYFrames[index] + rowsum[rowsum.size() -1 - (midFrameIndex-1) * pxHeight/index];

					#we will assume that the middle of the frame should have
					#the most alpha!  Subtract it
					potentialYFrames[index] =potentialYFrames[index] - rowsum[ceil(pxHeight/(index*2)) + (midFrameIndex-1) * pxHeight/index];

				

				#make this an average
				potentialYFrames[index]=potentialYFrames[index]/index;
				#prioritize more frames over fewer (slightly)
				potentialYFrames[index]=potentialYFrames[index]*(index-lowFrameCountPenalty)/index;
			
		
		
		#potentialXFrames
		var maxXValue=potentialXFrames.max();
		var bestXFrame=potentialXFrames.find_last(maxXValue)
		#potentialYFrames
		var maxYValue=potentialYFrames.max();
		var bestYFrame=potentialYFrames.find_last(maxYValue)
		print(bestXFrame,',',bestYFrame)
	


func waitDoesGodotSERIOUSLYNotHaveANativeMeanOrSumFunctionForArraysWTF(myArray):
	var arrayMean = 0
	
	for arrayEntry in myArray:
		arrayMean+=arrayEntry/(myArray.size())
		
	pass
	return arrayMean
