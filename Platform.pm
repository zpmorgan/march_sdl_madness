package Platform;
use Moose;

#a platform is a contiguous series of tiles that can be navigated by its entity,

# y is the y coordinate of solid tile with space above

has 'y' => (
   is => 'ro',
   isa => 'Int',
);
has 'left_x' => (
   is => 'ro',
   isa => 'Int',
);

has 'right_x' => (
   is => 'ro',
   isa => 'Int',
);
has 'left_x' => (
   is => 'ro',
   isa => 'Int',
);
has 'right_edge' => (
   is => 'ro',
   isa => 'Str',
);
has 'left_edge' => (
   is => 'ro',
   isa => 'Str',
);



1
