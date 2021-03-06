package Entity;
use Moose;

use Platform;
use Wall;
use Collision::2D ':all';
use POSIX 'floor';

has 'name' => (
   is => 'ro',
   isa => 'String',
);
has 'level' => (
   is => 'rw',
   isa => 'Level',
);
has 'sprite' => (
   is => 'rw',
   isa => 'Ref',
);

has $_ => (
   is => 'rw',
   isa => 'Num',
   default => 0,
) for qw/ x y  xv yv  x_acc y_acc/;

has $_ => (
   is => 'rw',
   isa => 'Num',
   default => .9999,
) for qw/ w h/;

has gravity => (
   is => 'rw',
   isa => 'Num',
   default => .01,
);

has platform => (
   is => 'rw',
);
has left_wall => (
   is => 'rw',
);
has right_wall => (
   is => 'rw',
);

# walking, freefall, etc
has 'status' => (
   is => 'rw',
   isa => 'Str',
   lazy => 1,
   default => sub{ $_[0]->determine_status}
);

has $_ => (
   is => 'rw',
   isa => 'Int',
) for qw/ bound_r bound_l /;

sub newb{
   my $class = shift;
   my $self = bless {@_},$class;
   die 'noname entity' unless defined $self->name;
   return $self;
}

sub do{
   my $self = shift;
   die "entity $self->{name} needs level" unless $self->{level};
   my $status = $self->{status};
   die "entity $self->{name} needs status (walking,freefall,etc.)" unless $status;
   my $crystalmethod = "do_$status";
   #warn $crystalmethod;
   $self->$crystalmethod;
   
}

sub do_standing{
   my $self = shift;
   
   #start walking if unblocked and accelerating.
   if ($self->{x_acc}){
      if (  ( $self->{x_acc} > 0 and $self->{bound_r})
         or ( $self->{x_acc} < 0 and $self->{bound_l}) ){
         $self->{status} = 'walking';
         $self->do_walking;
      }
   }
}


sub do_walking{
   my $self = shift;
   $self->{xv} += $self->{x_acc};
   
   #stop if blocked by a wall or something
   if ($self->{xv} > 0 && $self->{bound_r}){
      $self->{xv} = 0;
   }
   if ($self->{xv} < 0 && $self->{bound_l}){
      $self->{xv} = 0;
   }
   
   my $platform = $self->platform;
   #moving left towards wall?
   if ($self->{xv} < 0  and  $platform->left_edge eq 'wall'){
      if ($self->{x} + $self->{xv} < $platform->left_x){
         $self->{x} = $platform->left_x;
         $self->{xv} = 0;
         $self->{bound_l} = 1;
         $self->establish_wall ('l', $platform->left_x-1);
         return;
      }
   }
   #moving right towards wall?
   elsif ($self->{xv} > 0  and  $platform->right_edge eq 'wall'){
      if ($self->{x} + $self->{xv} + $self->w > $platform->right_x+1){
         $self->{x} = $platform->right_x +1 - $self->w;
         $self->{xv} = 0;
         $self->{bound_r} = 1;
         $self->establish_wall ('r', $platform->right_x+1);
         return;
      }
   }
   #moving left towards cliff?
   elsif ($self->{xv} < 0  and  $platform->left_edge eq 'cliff'){
      #allow standing on cliff edge
      if ($self->{x} + $self->{xv} < $platform->left_x - $self->w){
         $self->{x} += $self->xv;
         $self->set_freefall;
         return;
      }
   }
   #moving right towards cliff?
   elsif ($self->{xv} > 0  and  $platform->right_edge eq 'cliff'){
      #allow standing on cliff edge
      if ($self->{x} + $self->{xv} > $platform->right_x + 1){
         $self->{x} += $self->xv;
         $self->set_freefall;
         return;
      }
   }
   #eliminate boundedness if still moving horizontally
   if ($self->xv){
      $self->bound_l(0);
      $self->bound_r(0);
      $self->left_wall(undef);
      $self->right_wall(undef);
      $self->{x} += $self->xv
   }
} 

sub do_freefall{
   my $self = shift;
   
   #update velocity.
   $self->xv($self->xv+$self->x_acc);
   $self->yv($self->yv+$self->gravity);
   $self->xv(0) if ($self->xv < 0 and $self->bound_l);
   $self->xv(0) if ($self->xv > 0 and $self->bound_r);
   
   my $crect = $self->collision_rect;
   my $collision = dynamic_collision($self->level->{cgrid}, $crect);
   if ($collision and $collision->axis){
      if ($collision->axis eq 'y'){ #vertical collision
         $self->{x} += $self->xv * $collision->time*.999;
         $self->{y} += $self->yv * $collision->time*.999; 
         if ($self->yv > 0){ #vertical collision with floor..
            #now make y an int
            $self->{y} = floor ($self->y+.001);
            $self->yv(0);
            $self->set_status('walking');
            return;
         } 
         else { #vertical collision with ceiling.. 
            $self->{yv} *= -.25;
            return;
         }
      }
      else { #horizontal collision
         $self->{x} += $self->xv * $collision->time;
         $self->{y} += $self->yv * $collision->time;
         if ($self->xv > 0){
            $self->bound_r(1);
            $self->establish_wall('r', int($self->x+$self->w+.01) );
            $self->xv(0);
         }
         elsif ($self->xv < 0){
            $self->bound_l(1);
            $self->establish_wall('l', int($self->x -1 +.01) );
            $self->xv(0);
         }
         else{
            die 'what manner of collision is this?'
         }
         return;
      }
   }
   #eliminate boundedness if still moving horizontally
   if ($self->xv){
      $self->bound_l(0);
      $self->bound_r(0);
      $self->left_wall(undef);
      $self->right_wall(undef);
   }
   
   $self->{y} += $self->yv;
   $self->{x} += $self->xv;
}

#return 0 if instersects with solid tiles; else 1
sub in_space{
   my $self = shift;
   my $left_bound = (int ($self->x));
   my $right_bound = (int ($self->x + $self->w));
   my $up_bound = (int ($self->y));
   my $down_bound = (int ($self->y + $self->h));
   for my $ty ($up_bound .. $down_bound){
      for my $tx ($left_bound .. $right_bound){
         return 0 if $self->level->solid($tx,$ty);
      }
   }
   #it checks out.
   return 1;
}

sub perturb{
   my $self = shift;
   $self->{x}-- if (rand()<.2  and $self->x > 1);
   $self->{y}-- if (rand()<.2  and $self->y > 1);
   $self->{x}++ if (rand()<.2  and $self->x + $self->w < $self->level->{w}-1);#don't escape level bounds.
   $self->{y}++ if (rand()<.2  and $self->y + $self->h < $self->level->{h}-1);
}

sub perturb_if_necessary{
   my $self = shift;
   unless ($self->in_space){
      #make it more convenient
      $self->{y} = int ($self->{y}) +1 -$self->h;
      $self->{x} = int $self->{x};
      
   }
   until ($self->in_space){
      $self->perturb;
   }
   
}

sub determine_status{
   my $self = shift;
   
   $self->x(int $self->x);
   $self->y(int ($self->y)+1-$self->h);
   
   #perturb until non-solid
   $self->perturb_if_necessary;
   
   # solid ground at feet?
   if ($self->level->solid ($self->x, $self->y+$self->h)){
      $self->set_walking;
      $self->establish_platform ($self->y+$self->h);
   }
   else {
      $self->set_status ('freefall');
   }
}

sub set_walking{
   my $self = shift;
   my $y_floor = floor($self->y + $self->h + .001);
   $self->establish_platform($y_floor);
   $self->status('walking');
   
}
sub set_freefall{
   my $self = shift;
   $self->platform(undef);
   $self->status('freefall');
}

sub set_status{
   my ($self, $status) = @_;
   $self->{status} = $status;
   if ($status eq 'walking'){
      #die 'use set_walking instead of set status "walking"';
      $self->set_walking;
   }
   
   #~ if ($status =~ /walking|standing/){
      #~ if ( $self->{y} - int($self->{y}) ){
         #~ die "make sure y is an int before setting walking or standing"
      #~ }
      #~ unless ($self->{platform}){
         #~ $self->establish_platform;
      #~ }
   #~ }
}

sub establish_platform{
   my $self = shift;
   my $py = shift;
   my $level = $self->level;
   #~ my $py = $self->{y} + 1;
   
   #
   my @candidate_x = (int $self->x, int $self->x+1);
   @candidate_x = grep {$level->solid($_, $py)  and  ! $level->solid($_, $py-1)} @candidate_x;
   
   if ($#candidate_x < 0){
      $self->level->dump;
      die "platformless";
   }
   #probe navigable tiles. Won't work for 1x2 or 2x1 entities.
   my ($l,$r) = ($candidate_x[0],$candidate_x[0]);
   while(1){
      if ($level->solid($l-1,$py)  and  ! $level->solid($l-1,$py-1) ){
         $l--;
      }
      else{ last }
   }
   while(1){
      if ($level->solid($r+1,$py)  and  ! $level->solid($r+1,$py-1) ){
         $r++;
      }
      else{ last }
   }
   
   my ($l_edge, $r_edge);
   
   #determine wall or cliff for each side
   if ($level->solid($l-1,$py-1)) {
      $l_edge = "wall";
   }
   else{
      $l_edge = "cliff" }
   
   if ($level->solid($r+1,$py-1)) {
      $r_edge = "wall";
   }
   else{
      $r_edge = "cliff" }
   
   
   my $platform = Platform->new(
      y => $py,
      left_x => $l,
      right_x => $r,
      left_edge => $l_edge,
      right_edge => $r_edge,
   );
   #die "$py: $l $l_edge , $r $r_edge";
   $self->platform($platform);
}

sub establish_wall{
   my ($self,$side,$x) = @_;
   my $d = ($side eq 'l') ? 1 : -1;
   
   my $fst_y = int($self->y);
   if ($self->level->solid($x,$fst_y) and !$self->level->solid($x+$d,$fst_y)){
      $fst_y++;
      #die 'foo' unless $self->level->solid($x,$fst_y) and !$self->level->solid($x+$d,$fst_y);
   }
   my ($top,$bottom) = ($fst_y, $fst_y);
   while($self->level->solid($x,$top-1) and !$self->level->solid($x+$d,$top-1)){
      $top--;
   }
   while($self->level->solid($x,$bottom-1) and !$self->level->solid($x+$d,$bottom-1)){
      $bottom++;
   }
   my $top_edge = $self->level->solid($x+$d,$top-1) ? 'solid' : 'space';
   my $bottom_edge = $self->level->solid($x+$d,$bottom+1) ? 'solid' : 'space';
   
   my $wall = Wall->new(
      x => $x,
      side => $side,
      top_y => $top,
      bottom_y => $bottom,
      top_edge => $top_edge,
      bottom_edge => $bottom_edge,
   );
   #die "$py: $l $l_edge , $r $r_edge";
   $self->left_wall ($wall) if ($side eq 'l');
   $self->right_wall($wall) if ($side eq 'r');
}

sub collision_rect{
   my $self = shift;
   my $crect = hash2rect {
      x=>$self->x,
      y => $self->y,
      xv => $self->xv,
      yv => $self->yv,
      w => $self->w,
      h => $self->h,
   };
   
   return $crect;
}

sub center{
   my $self = shift;
   return ($self->x + $self->w/2, $self->y + $self->h/2)
}

1

