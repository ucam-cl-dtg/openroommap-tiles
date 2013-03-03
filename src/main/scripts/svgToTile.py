#!/usr/bin/python

from subprocess import check_output
from PIL import Image
import xml.sax
import os
import shutil
import re
import sys
inkscape = "/usr/bin/inkscape"

DEBUG=0

class CompletedException(Exception):
    def __init__(self,width,height):
        self.width = width
        self.height = height

class Finder(xml.sax.handler.ContentHandler):
    def startElement(self, name, attrs):
        if name == "svg":
            width = float(attrs["width"])
            height = float(attrs["height"])
            raise CompletedException(width,height)

def getSize(filename):
    parser = xml.sax.make_parser()
    finder = Finder()
    parser.setContentHandler(finder)
    try:
        parser.parse(filename)
    except CompletedException as c:
        return (c.width,c.height)


"""
Produce enough PNGs of dimensions tileSizePx so that when they are put
together we get an image of size renderSizePx
"""
def slice(filename,w,h,renderSizePx,tileSizePx,workingDir):
    n = renderSizePx / tileSizePx
    pieceSize = w/float(n)
    for x in range(0,n):
        for y in range(0,n):
            bounds = (pieceSize*x,
                      pieceSize*y,
                      pieceSize*(x+1),
                      pieceSize*(y+1))
            tileName = "%s/tile-%d-%d-%d-%d.png" % (workingDir,renderSizePx,tileSizePx,x,y)
            if DEBUG != 0:
                print "RENDER\t%s" % (tileName)
            check_output([inkscape,
                          "-a","%f:%f:%f:%f" % bounds,
                          "-w",str(tileSizePx),
                          "-e",tileName,
                          filename])

# Work through the tiles which we have made and split them again into the correct size
def sliceFiles(workingDir,targetTileSize):
    for f in os.listdir(workingDir):
        m = re.match('tile-(\d+)-(\d+)-(\d+)-(\d+).png',f)
        if m:
            (renderSizePx,tileSizePx,masterX,masterY) = map(lambda x:int(x),m.groups())
            if tileSizePx != targetTileSize:
                scale = tileSizePx / targetTileSize
                (realX,realY) = (masterX*scale,masterY*scale)
                master = Image.open(os.path.join(workingDir,f))
                for (i,x) in enumerate(range(0,tileSizePx+1,targetTileSize)):
                    for (j,y) in enumerate(range(0,tileSizePx+1,targetTileSize)):
                        filename= os.path.join(workingDir,
                                               "tile-%d-%d-%d-%d.png" % (renderSizePx,targetTileSize,realX+i,realY+j))
                        if not os.path.exists(filename):
                            im = master.crop((x,y,x+targetTileSize,y+targetTileSize))
                            if DEBUG != 0:
                                print "CROP\t%s" %(filename)
                            im.save(filename)

def main(svgfile,workingdir,template):
    targetTileSize = 256
    zoomStop = 6
    (w,h) = getSize(svgfile)

    for zoom in range(0,zoomStop):
        n = 1<<zoom
        neededSize = n*targetTileSize
        chosenSize = min(neededSize,4096)
        slice(svgfile,w,h,neededSize,chosenSize,workingDir)
    sliceFiles(workingDir,targetTileSize)

    for zoom in range(0,zoomStop):
        n = 1<<zoom
        size = n * targetTileSize
        for i in range(0,n):
            for j in range(0,n):
                sourceFile = os.path.join(workingDir,
                                          "tile-%d-%d-%d-%d.png" % (size,targetTileSize,i,j))
                if not os.path.exists(sourceFile):
                    print "Source %s not found - something's gone wrong" % (sourceFile)
                else:
                    shutil.copy2(sourceFile,"%s-%d-%d-%d.png" % (template,zoom,i,j))
if __name__ == "__main__":
#    svgfile = "floor2-people.svg"
#    workingDir = "temp"
#    template = "tile/subpeople-2"
    
    (svgfile,workingDir,template) = (sys.argv[1],sys.argv[2],sys.argv[3])

    if os.path.exists(workingDir):
        shutil.rmtree(workingDir)
    os.mkdir(workingDir)    
    main(svgfile,workingDir,template)
    shutil.rmtree(workingDir)
