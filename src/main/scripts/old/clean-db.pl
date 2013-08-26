use DBI;
use strict;

my $dbh = DBI->connect("dbi:Pg:dbname=openroommap;host=localhost;port=5432","orm","openroommap", {AutoCommit => 0}) or
 die "Failed to connect to database\n";

$dbh->do("update placed_item_update_table set deleted='t' where update_id in (SELECT update_id from placed_item_update_table, placed_item_table where last_update = update_id and not (x > 926.26 and x < 1007.799 and y > 995.5 and y < 1074) and deleted='f');");

$dbh->disconnect();
