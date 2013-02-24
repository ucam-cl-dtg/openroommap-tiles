use DBI;
use strict;
my $dbh = DBI->connect("dbi:Pg:dbname=openroommap;host=localhost;port=5433","orm","openroommap", {AutoCommit => 0}) or die "Failed to connect to database\n";
my $r = $dbh->selectall_arrayref("select max(update_id) from placed_item_update_table;");
print $r->[0]->[0],"\n";   
$dbh->disconnect();