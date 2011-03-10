package Level;
use warnings;
use strict;
use feature 'say';

use Viewport;
use Platform;
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
      @_,
   };
   bless $self,$class;
   if ($self->{size}){
      $self->{w} = $self->{h} = $self->{size}
   }
   for (qw/ size tiles tiletypes w h default_tile tilesize /){
      die "level needs $_" unless $self->{$_}
   }
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
   die;
   my ($self,$surf) = @_;
   for my $ty (0..$self->{h}-1){
      for my $tx (0..$self->{w}-1){
         my $tile = $self->{tiles}[$ty][$tx] // $self->{default_tile};
         die unless defined $tile;
         my $tileclass = $self->{tiletypes}{$tile} || die "tile $tile what?";
         if ($tileclass->{file}){
            fail_somehow();
         }
         elsif ($tileclass->{color}){
            $surf->draw_rect( [ $tx*32,$ty*32, 32, 32 ], $tileclass->{color} );
         }
         # else empty space. parallax background would be neat.
      }
   }
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
   
   #falling? freefall?
   $entity->determine_status;
   
   push @{$self->{entities}}, $entity;
}

sub solid{
   my ($self, $x, $y) = @_;
   confess unless defined $x;
   my $tile = $self->{tiles}[$y][$x];
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

1
