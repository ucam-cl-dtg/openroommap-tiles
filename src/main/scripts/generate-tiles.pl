# for floor in `seq 2 -1 0`; do perl t2.pl $floor > map.svg; for a in `seq 0 1 5`; do WIDTH=$(( (1<<$a)*256 )); inkscape map.svg -e map.png -w $WIDTH -b "#FFFFFF"; convert -crop 256x map.png tile-$floor-$a-%d.png; for b in tile-$floor-$a-*; do convert -crop x256 $b sub`basename $b .png`-%d.png;done;rm tile-*; done; done

# select min(x),min(y),max(x),max(y) from (select t2.maxx -t1.x as x ,t2.maxy-t1.y as y from floorpoly_table t1, (select max(x) as maxx,max(y) as maxy from floorpoly_table) t2 where polyid = (select polyid from room_table natural join roompoly_table where name ='SN13')) t2;


use DBI;
use strict;

my $floor = $ARGV[0];
my $people = ($ARGV[1] =~ /people/ ? 1 : 0);
my $rooms = ($ARGV[1] =~ /rooms/ ? 1 : 0);
my $objects = ($ARGV[1] =~ /objects/ ? 1 : 0);
my $desksOnly = ($ARGV[1] =~ /desksOnly/ ? 1 : 0);
my $labels = ($ARGV[1] =~ /labels/ ? 1 : 0);
my $stderrroomvectors = 0;

my $roomFill = $objects == 0 ? 'fill="#cccccc" fill-opacity="0.10" stroke="none" vector-effect="non-scaling-stroke" ' : 'fill="none" stroke="none" vector-effect="non-scaling-stroke" ';
my $roomStroke = 'fill="none" stroke="#000000" stroke-width="0.05" stroke-linejoin="round" stroke-linecap="round" vector-effect="non-scaling-stroke" ';

my $dbh = DBI->connect("dbi:Pg:dbname=openroommap;host=localhost;port=5433","orm","openroommap", {AutoCommit => 0}) or
 die "Failed to connect to database\n";

my $r = $dbh->selectall_arrayref("SELECT -max(x),-min(x),min(y),max(y) from floorpoly_table;");
my ($minX,$maxX,$minY,$maxY) = @{$r->[0]};   
my ($width,$height) = ($maxX-$minX,$maxY-$minY);
if ($width < $height) {
    $maxX += ($height - $width);
}
if ($height < $width) {
    $maxY += ($width - $height);
}
($width,$height) = ($maxX-$minX,$maxY-$minY);

#print STDERR "$minX,$minY,$maxX,$maxY\n";

my $document;

my $r = $dbh->selectall_arrayref("SELECT polyid from submappoly_table where submapid =$floor;");
foreach my $row (@$r) {
    my $polyid = $row->[0];
    if ($stderrroomvectors == 1) {
	my $rm = $dbh->selectall_arrayref("select name from room_table, roompoly_table where room_table.roomid = roompoly_table.roomid and roompoly_table.polyid = $polyid limit 1");
	my $roomname = $rm->[0]->[0]; 
	print STDERR "# $roomname\n";
    }
    my $v = $dbh->selectall_arrayref("SELECT x,y,edgetarget FROM floorpoly_table where polyid=$polyid  order by vertexnum ASC");
    my $fillData;
    my $strokeData;
    my $pet;
    my $first = "none";
    foreach my $vertex (@$v) {
	my ($v1,$v2,$et) = (-$vertex->[0],$vertex->[1],$vertex->[2]);
	if ($pet) {
	    $strokeData .= "M $v1 $v2 ";
	}
	else {
	    $strokeData .= "L $v1 $v2 ";
	}
	if ($stderrroomvectors == 1) {
	    if ($first eq "none") { $first = "$v1 $v2"; }
	    print STDERR "$v1 $v2\n";
	}
	$pet = $et;
	$fillData .= "L $v1 $v2 ";
    }
    if ($stderrroomvectors == 1) {
	print STDERR "$first\n";
	print STDERR "\n";
    }
    $fillData =~ s/^L/M/;
    $strokeData =~ /^((?:L|M)[^LM]+ )/;
    my $first = $1;
    if ($pet) {
	$first =~ s/L/M/;
    }
    else {
	$first =~ s/M/L/;
    }
    $strokeData .= $first;
    $strokeData =~ s/^L/M/;
    $fillData .= "z";
    if ($rooms == 1) { $document .= "<path d=\"$fillData\" $roomFill/>\n"; }
#    $document .= "<path d=\"$strokeData\" $roomStroke/>\n";
}

my $deskFilter = "";
if ($desksOnly == 1) {
    $deskFilter = "where def_id in (3,4,5,6,7,11,34,35,37)";
}
my $items = $dbh->selectall_arrayref("SELECT name,def_id from item_definition_table $deskFilter order by height asc");
foreach my $item (@$items) {
    my ($name,$defid) = @$item;
    my $polyDefs = $dbh->selectall_arrayref("SELECT poly_id, fill_colour,fill_alpha,edge_colour,edge_alpha FROM item_polygon_table where item_def_id = $defid");
    my @itemPolys;
    foreach my $polyDef (@$polyDefs) {
	my ($poly_id,$fill_colour,$fill_alpha,$edge_colour,$edge_alpha) = @$polyDef;
	my $vertices = $dbh->selectall_arrayref("SELECT x,y FROM item_polygon_vertex_table WHERE poly_id=$poly_id ORDER BY vertex_id asc");
	my @polyVertices;
	foreach my $vertex (@$vertices) {
	    my ($v1,$v2) = ($vertex->[0],$vertex->[1]);
	    push(@polyVertices,[$v1,$v2]);
	}
	push(@itemPolys,[&intToRGB($fill_colour),$fill_alpha,&intToRGB($edge_colour),$edge_alpha,\@polyVertices]);
    }
    my $placements = $dbh->selectall_arrayref("select x,y,theta,flipped,floor_id from placed_item_update_table, placed_item_table where last_update = update_id and item_def_id = $defid and floor_id=$floor and deleted='f'");
  LABEL: foreach my $placement (@$placements) {
	my ($cx,$cy,$theta,$flipped,$floor) = @$placement;
	$theta = -$theta / 180 * 3.14159265358979323846;
	foreach my $itemPoly (@itemPolys) {
	    my ($fill_colour,$fill_alpha,$edge_colour,$edge_alpha,$polyVertices) = @$itemPoly;
	    my $pathData;
	    foreach my $vertex (@$polyVertices) {
		my ($vx,$vy) = ($vertex->[0],$vertex->[1]);
		if ($flipped =~ /1/) {
		    $vy *= -1;
		}
		my $x = -($vx*cos($theta) + $vy*sin($theta) + $cx);
		my $y = $vy*cos($theta) - $vx*sin($theta) + $cy;
		$pathData .= "L $x $y ";
		next LABEL if ($x > $maxX || $x < $minX || $y > $maxY || $y < $minY);		
	    }
	    $pathData =~ s/^L/M/;
	    $pathData .= "z";
	    if ($objects == 1) { $document .= "<path d='$pathData' fill='$fill_colour' fill-opacity='$fill_alpha' stroke='$edge_colour' stroke-opacity='$edge_alpha' stroke-width='0.05' vector-effect='non-scaling-stroke'/>\n"; }
	}
    }
}

my %usedRooms;
my $r = $dbh->selectall_arrayref("SELECT polyid from submappoly_table where submapid =$floor;");
foreach my $row (@$r) {
    my $polyid = $row->[0];
    my $v = $dbh->selectall_arrayref("SELECT x,y,edgetarget FROM floorpoly_table where polyid=$polyid  order by vertexnum ASC");
    my $fillData;
    my $strokeData;
    my $pet;
    my ($midx,$midy,$count) = (0,0,0);
    foreach my $vertex (@$v) {
	my ($v1,$v2,$et) = (-$vertex->[0],$vertex->[1],$vertex->[2]);
	if ($pet) {
	    $strokeData .= "M $v1 $v2 ";
	}
	else {
	    $strokeData .= "L $v1 $v2 ";
	}
	$pet = $et;
	$fillData .= "L $v1 $v2 ";
	$midx += $v1;
	$midy += $v2;
	$count++;
    }
    $midx /= $count;
    $midy /= $count;
    $fillData =~ s/^L/M/;
    $strokeData =~ /^((?:L|M)[^LM]+ )/;
    my $first = $1;
    if ($pet) {
	$first =~ s/L/M/;
    }
    else {
	$first =~ s/M/L/;
    }
    $strokeData .= $first;
    $strokeData =~ s/^L/M/;
    $fillData .= "z";
 #   $document .= "<path d=\"$fillData\" $roomFill/>\n";
    if ($rooms == 1) { $document .= "<path d=\"$strokeData\" $roomStroke/>\n"; }
    if ($labels == 1) {
	my $rm = $dbh->selectall_arrayref("select name from room_table, roompoly_table where room_table.roomid = roompoly_table.roomid and roompoly_table.polyid = $polyid limit 1");
	foreach my $rmrow (@$rm) {
	    if (!exists($usedRooms{$rmrow->[0]})) {
		my $h = 1.265015;
		my $w = 2.5195167;
		my $bx = $midx-$w/2;
		my $by = $midy-$h/2-0.252;
		$document .= "<g><rect height=\"$h\" width=\"$w\" rx=\"0.44194168\" ry=\"0.31694031\" x=\"$bx\" y=\"$by\" style=\"opacity:1;fill:#ffffff;fill-opacity:1;stroke:#000000;stroke-width:0.06;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:0;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1\" /><text x=\"$midx\" y=\"$midy\" dominant-baseline=\"central\" style=\"font-size:0.6934762px;font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;text-align:center;line-height:100%;writing-mode:lr-tb;text-anchor:middle;opacity:1;fill:#000000;fill-opacity:1;stroke:none;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;font-family:Bitstream Vera Sans;-inkscape-font-specification:Bitstream Vera Sans\">$rmrow->[0]</text></g>\n";
		$usedRooms{$rmrow->[0]}= 1;
	    }
	}
    }
    if ($people == 1) {
	my $plp = $dbh->selectall_arrayref("select x,y,label from placed_item_table, placed_item_update_table where placed_item_table.last_update = placed_item_update_table.update_id and placed_item_table.item_def_id=47 and deleted = false and floor_id = $floor");
	foreach my $plprow (@$plp) {
	    my ($x,$y,$label) = @$plprow;
	    $x *= -1;
	    $document .= "<g>";
	    my ($ws,$hs) = (2.5195167/1.5,1.265015/1.5);
	    my ($rx,$ry) = ($ws*0.125,$ws*0.125);
	    my ($xs,$ys) = ($x - $ws/2, $y - $hs/2 - 0.08);
	    $document .= "<rect style=\"opacity:1;fill:#ffffff;fill-opacity:1;stroke:#000000;stroke-width:0.04;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:0;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1\" height=\"$hs\" width=\"$ws\" x=\"$xs\" y=\"$ys\" ry=\"$ry\" rx=\"$rx\" />";
	    $document .= "<text x=\"$x\" y=\"$y\" dominant-baseline=\"central\" style=\"font-size:0.2934762px;font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;text-align:center;line-height:100%;writing-mode:lr-tb;text-anchor:middle;opacity:1;fill:#000000;fill-opacity:1;stroke:none;stroke-width:0px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;font-family:DejaVu Sans;inkscape-font-specification:DejaVu Sans\">$label</text></g>\n";
	}

    }
}

print '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">'."\n";
print "<svg width='$width' height='$height' version='1.1' xmlns='http://www.w3.org/2000/svg'>\n";
print "<g transform='translate(".-$minX.",".-$minY.")'>\n";
print $document;
print "</g>\n'";

print "</svg>\n";




sub intToRGB() {
    my ($i) = @_;
    my $r = ($i >> 16) & 0xFF;
    my $g = ($i >> 8) & 0xFF;
    my $b = $i & 0xFF;
    return "rgb($r,$g,$b)";
}
