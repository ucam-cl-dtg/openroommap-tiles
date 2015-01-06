#*******************************************************************************
# Copyright 2014 Digital Technology Group, Computer Laboratory
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.
#*******************************************************************************
use DBI;
use strict;

my $port = $ARGV[0];

my $dbh = DBI->connect("dbi:Pg:dbname=openroommap;host=localhost;port=$port","orm","openroommap", {AutoCommit => 0}) or die "Failed to connect to database\n";
my $r = $dbh->selectall_arrayref("select max(update_id) from placed_item_update_table;");
print $r->[0]->[0],"\n";   
$dbh->disconnect();
