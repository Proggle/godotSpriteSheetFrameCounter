extends Node2D
#Takes the texture attached to Sprite and estimates how many rows and columns
# of sprites are contained in the sheet
# proof of concept so not optimized at all, there are serious improvements
# that can be made here by moving out of gdscript.
# The lag isn't noticeable for me on anything other than egregiously large 
# sheets like spritesheet_players (1024x2048), but obviously any lag is no good.

#Spritesheets in the Kenney_Sprites folder are from Kenney, released under CC0
# https://kenney.nl/assets 
#Ars_Notoria sprites by Balmer, released under CC0 
# https://opengameart.org/content/hero-spritesheets-ars-notoria 
#Superpowers sprite by Pixel-Boy, released under CC0
# https://github.com/sparklinlabs/superpowers-asset-packs 

#this performs best on sprites surrounded by transparency on all four sides, 
#which is relatively easy to detect.  In cases where the sprite extends all the
#way to the edge, it gets dicier.

#in particular, it struggles with sheets that have very little transparency,
#like spritesheet_tiles
#That said, it does surprisingly well with Ars_Notoria_02, which is a tiny piece 
#of equipment that is supposed to be overlaid on the shirtless guy, and which
#is swimming in an empty sea of transparency.

#The sprites in Kenney/Unaligned_sheets are ones that don't follow a consistent
#grid.  My current approach can't really do anything with them.
#I am including them in case someone wants a challenge when extending this.

#Tilesets (which usually have no transparency) aren't going to work as well.
#I suspect you could get somewhere by assuming the tile is square and doing some
#fourier transform stuff on it, but that's beyond the scope of what I can do in
#gdscript.



#and realistically you could probably do this entire thing more effectively by
#finding local minima and maxima, but gdscript doesn't have much math support
#so I'm going with what the language can provide.

onready var spriteSheet= $Sprite

onready var sheetSize = spriteSheet.texture.get_size();

onready var pxWidth: int =sheetSize.x
onready var pxHeight: int =sheetSize.y

#one of the big problems is trying to sort out harmonics - a 9x9 sprite sheet
# with nice transparent frames around each sprite can be hard to distinguish
# from a 3x3 sprite sheet 
# in principle there might be a more effective way to differentiate, but
# instead I am just penalizing small frame counts compared to higher ones
# so if two counts are both plausible, it'll pick the one with more frames.
var lowFrameCountPenalty=0.3; 
#Number was tuned experimentally

# Called when the node enters the scene tree for the first time.
func _ready():

	var columnsum = [0.0]
	var rowsum = [0.0]
	columnsum.resize(pxWidth);
	rowsum.resize(pxHeight);
	columnsum.fill(0.0)
	rowsum.fill(0.0)
	

	# I really don't like hard abitrary limits on magic numbers in general, but
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
	# using spriteSheet.texture.get_data().data.data 
	# but that's at least three times too much "data" for me.
	# So screw it, pixel-by-pixel it is!
	sheetImage.lock()
	for xindex in range (0,pxWidth):
		for yindex in range(0,pxHeight):
			var myPix=sheetImage.get_pixel(xindex,yindex)	
			columnsum[xindex]= columnsum[xindex]+1-float(myPix.a) # switch alpha values around so we are measuring transparency
			rowsum[yindex]= rowsum[yindex]+1-float(myPix.a) # switch alpha values around so we are measuring transparency
			
	sheetImage.unlock()
	

		
		
		#check if the alpha channel actually matters.
	if (columnsum.max()==columnsum.min() && rowsum.max() == rowsum.min()):
		print('file has no alpha variation')
	else:
		for numFrames in range( 1,maxXFrameNumber+1):
			if (pxWidth%numFrames==0):
				for midFrameIndex in range(1,numFrames+1):
					#give a score based on how many clear lines we have at the edge and how many 
					#nonclear lines we have in the center
					potentialXFrames[numFrames] +=weightTransparentCount(columnsum,pxHeight,numFrames,midFrameIndex)

				#prioritize more frames over fewer (slightly)
				potentialXFrames[numFrames]=potentialXFrames[numFrames]*(numFrames-lowFrameCountPenalty)/numFrames;
			
		
		for numFrames in range( 1,maxYFrameNumber+1):
			if ( pxHeight%numFrames ==0):
				for midFrameIndex in range(1,numFrames+1):
					#give a score for how many clear lines we have at the edge and how many 
					#nonclear lines we have in the center
					potentialYFrames[numFrames] +=weightTransparentCount(rowsum,pxWidth,numFrames,midFrameIndex)
					
				#prioritize more frames over fewer (slightly)
				potentialYFrames[numFrames]=potentialYFrames[numFrames]*(numFrames-lowFrameCountPenalty)/numFrames;
			
		
		
		#potentialXFrames
		var maxXValue=potentialXFrames.max();
		var bestXFrame=potentialXFrames.find_last(maxXValue)
		#potentialYFrames
		var maxYValue=potentialYFrames.max();
		var bestYFrame=potentialYFrames.find_last(maxYValue)
		print('The frames are probably a ',bestXFrame,' by ',bestYFrame, ' rectangle.')
	


#counts the number of transparent pixels on each edge, applies a 2x bonus for each 'perfect' edge,
#and an additional 2x bonus for having all perfect edges and centers
#all other things being equal, a grid that finds sprites surrounded on all 4 sides by a box of
#transparency is probably the correct one.
#but if we don't find anything like that, we go to the closest box
func  weightTransparentCount(sumArray,maxValue,numFrames,midFrameIndex):
	var currPixelStart=(midFrameIndex-1) * (sumArray.size()/numFrames) -1;
	var weightedSumVal = 0.0;
	var perfectLines=0.0;
	
	#increase the score for transparent pixels on the edge

	var addTestIndexes = [currPixelStart+1,currPixelStart + sumArray.size()/numFrames ];
	var numAddTests=addTestIndexes.size() * 1.0;
	for currTestIndex in addTestIndexes:
		weightedSumVal=weightedSumVal + (1.0/numAddTests) * sumArray[currTestIndex];
		#double points if you have a perfect edge with no opacity.
		if(sumArray[currTestIndex] == maxValue):
			weightedSumVal=weightedSumVal + (1.0/numAddTests) * sumArray[currTestIndex];
			perfectLines=perfectLines+1;
		
	
	#decrease the score for transparent pixels in the middle (centerline +-1/6 of the frame)
	var subtractTestIndexes=[currPixelStart +  ceil(sumArray.size()/(numFrames*2.0)+1.0),currPixelStart +  floor(sumArray.size()/(numFrames*3) ),currPixelStart +  ceil(2.0*sumArray.size()/(numFrames*3.0) )];
	
	var numSubtractTests=subtractTestIndexes.size() * 1.0
	for currTestIndex in subtractTestIndexes:
		
		weightedSumVal=weightedSumVal- (1.0/numSubtractTests) *sumArray[currTestIndex];
		#double penalty if you have a center that has no opacity.
		if(sumArray[currTestIndex] == maxValue):
			weightedSumVal=weightedSumVal- (1.0/numSubtractTests) *sumArray[currTestIndex];
			perfectLines=perfectLines-1;

	#if we have a perfect run on all sides
	#(ie: totally clear on each edge and not clear in the middle), 
	# then double the weight on this run. 
	if(perfectLines >= 2 ):   
		weightedSumVal=weightedSumVal*2;

	#normalize for number of frames
	weightedSumVal=weightedSumVal/numFrames;
	
	return weightedSumVal 

