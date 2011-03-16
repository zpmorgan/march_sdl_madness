package Wall;
use Moose;

#a wall is a vertical contiguous series of tiles that can be navigated by its entity,

# x is the y coordinate of solid tile with space right or left

has side => ( 
   is => 'ro',
   required => 1,
   #isa => 'Int',
);

has 'x' => (
   is => 'ro',
   isa => 'Int',
   required => 1,
);
has 'top_y' => (
   is => 'ro',
   isa => 'Int',
   required => 1,
);

has 'bottom_y' => (
   is => 'ro',
   isa => 'Int',
   required => 1,
);
has 'top_edge' => ( #space or floor
   is => 'ro',
   isa => 'Str',
   required => 1,
);
has 'bottom_edge' => ( #space or floor
   is => 'ro',
   isa => 'Str',
   required => 1,
);

1
