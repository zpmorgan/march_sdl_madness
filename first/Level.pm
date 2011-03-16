package Level;
use warnings;
use strict;
use feature 'say';

use Viewport;
use SDLx::Rect;
use Collision::2D ':all';
#use Collision::2D::Entity::Grid; 
#use Collision::2D::Entity::Rect;
use Carp;

# level should be chunky.

sub new{
   my $class = shift;
   my $self = {
      # tilesize. => 32
      # tiletypes. => {rock => {file=>'rock.png'} air => {solid=>0}}.
      # default_tile => try 'air' or whatever. for undefs in the level data
      # tiles => actual level data.[['grass','air','rock'], [second row] , etc.]
      # w => width, h => height.
      # default_solid and default_space are for level genration.
      @_,
   };
   bless $self,$class;
   if ($self->{size}){
      $self->{w} = $self->{h} = $self->{size}
   }
   for (qw/ size tiletypes w h default_tile tilesize /){
      die "level needs $_" unless $self->{$_}
   }
   $self->generate_terrain unless $self->{tiles};
   return $self;
}

sub init_collision_grid{
   my $self = shift;
   my $grid = hash2grid {x=>0, y=>0, w=>$self->{w}, h=>$self->{h},  cell_size => 2};
   for my $ty (0..$self->{h}-1){
      for my $tx (0..$self->{w}-1){
         if ($self->solid($tx, $ty)){
            $grid->add_rect( hash2rect {x=>$tx, y=>$ty, w=>1, h=>1});
         }
      }
   }
   $self->{cgrid} = $grid;
}

# use Viewport for maneuverability & screen positioning
sub draw{
   die 'levels don\'t draw. only viewports draw.';
}

sub basic_viewport{
   my $self = shift;
   my %params = @_;
   die "viewport needs app" unless $params{app};
   $params{surf_x} //= 0;
   $params{surf_y} //= 0;
   $params{level_x} //= 0;
   $params{level_y} //= 0;
   $params{w} //= $params{app};
   $params{h} //= 0;
   my $vp = new Viewport(level => $self, @_);
   return $vp;
}

sub add_entity{
   my ($self, $entity, %params) = @_;
   $entity->level($self);
   
   for (qw/ x y xv yv x_acc y_acc /){
      $entity->{$_} = $params{$_} if $params{$_};
   }
   
   #walking? freefall?
   $entity->determine_status;
   
   push @{$self->{entities}}, $entity;
}

sub solid{
   my ($self, $x, $y) = @_;
   confess unless defined $x;
   my $tile = $self->{tiles}[$y][$x];
   return 1 unless defined $tile;
   #solid by default
   return 1 unless defined $self->{tiletypes}{$tile}{solid};
   return $self->{tiletypes}{$tile}{solid};
}

sub dump{
   my $self = shift;
   for my $ty (0..$self->{h}-1){
      say join '', map {$self->solid($_,$ty)} (0..$self->{w}-1);
      
   }
}

sub generate_terrain{
   my $self = shift;
   
   my $iterations = 3;
   my $amountWalls = .45;
   #fill with 1s and 0s
   my @terrain = map   {[map {rand() < $amountWalls || 0} (1..$self->{w})]}   (1..$self->{h});
   
   my @next;
   
   #make borders solid. This ought to be extended to create paths & chunk links.
   my $do_borders = sub{
      for (0..$self->{w}-1){
         $next[0][$_] = 1;
         $next[$self->{h}-1][$_] = 1;
      }
      for (0..$self->{h}-1){
         $next[$_][0] = 1;
         $next[$_][$self->{w}-1] = 1;
      }
   };
   
   for (1..$iterations){
      @next = ();
      for my $row (1..$self->{h}-2){
         for my $col (1..$self->{w}-2){
            my $ct = 0;
            #count number of 1's in 3x3 proximity + itself
            for my $r ($row-1..$row+1) { 
               for my $c ($col-1..$col+1) {
                  $ct += 1 if $terrain[$r][$c] } };
            $next[$row][$col] = $ct>4||0;
         }
      }
      $do_borders->();
      #~ for (@$solid){
         #~ my ($col,$row) = @$_;
         #~ $next[$row][$col] = 1;
      #~ }
      #~ for (@$space){
         #~ my ($col,$row) = @$_;
         #~ $next[$row][$col] = 0;
      #~ }
      @terrain = @next;
   }
   #$self->decorate($terrain);
   #return $terrain;
   for my $row (1..$self->{h}-2){
      for my $col (1..$self->{w}-2){
         if ($terrain[$row][$col]){
            $terrain[$row][$col] = $self->{default_solid};
            #$terrain[$row][$col] .= 's' if rand() > .03;
         }
         else { 
            $terrain[$row][$col] = $self->{default_space}; 
         }
      }
   }
   $self->{tiles} = \@terrain;
}

1
