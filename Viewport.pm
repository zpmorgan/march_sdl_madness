package Viewport;
use warnings;
use strict;

use SDL::Rect;

#draw Level tiles & entities in a clipped, offset region.


sub new{
   my $class = shift;
   my $self = {
      # app => SDLx::Controller or SDL::Surface or SDLx::App
      # level => $level object.
      # w,h,level_x,level_y, surf_x, surf_y
      @_,
   };
   $self->{level_x} //= 0;
   $self->{level_y} //= 0;
   bless $self,$class;
   for (qw/app level  w h/){
      die "viewport needs $_" unless defined $self->{$_}
   }
   return $self;
}

sub draw{
   my $self = shift;
   my %params = @_;
   
   my $vp_app_rect = $self->app_rect();
   
   #make sure we have these parameters
   for (qw/ w h level_x level_y  surf_x  surf_y /){
      next if defined $params{$_};
      die "viewport draw needs $_" unless defined $self->{$_};
      $params{$_} = $self->{$_};
   }
   
   #figure out 2d range of tiles within viewport bounds
   my $tile_start_x = $params{level_x} / $self->tilesize;
   my $tile_end_x = 1 + ($params{level_x} + $params{w}) / $self->tilesize;
   my $tile_start_y = $params{level_y} / $self->tilesize;
   my $tile_end_y = 1 + ($params{level_y} + $params{h}) / $self->tilesize;
   
   for my $ty ($tile_start_y .. $tile_end_y){
      for my $tx ($tile_start_x .. $tile_end_x){
         my $tile = $self->{level}{tiles}[$ty][$tx] // $self->{default_tile};
         #die @{$self->{tiles}} unless defined $tile;
         my $tileclass = $self->{level}{tiletypes}{$tile} || die "tile $tile what?";
         
         my $tile_rect = SDL::Rect->new($tx*32,$ty*32, 32, 32 );
         my $clipped_tile_rect = $vp_app_rect->clip( $tile_rect );
         if ($tileclass->{file}){
            
         }
         elsif ($tileclass->{color}){
            $self->{app}->draw_rect( $clipped_tile_rect , $tileclass->{color} );
         }
         # else empty space. parallax background would be neat.
      }
   }
   for my $ent (@{$self->{level}{entities}}) {
      $ent->sprite->rect ( SDLx::Rect->new($ent->x*32, $ent->y*32, 16, 32 ) );
      $ent->sprite->rect->clip_ip ($vp_app_rect);
     # die $ent->sprite->y;
      $ent->sprite->draw ($self->{app}->surface);
   }
}

sub tilesize{
   return $_[0]{level}{tilesize};
}
sub app_rect{
   my $self = shift;
   return new SDLx::Rect($self->{surf_x}, $self->{surf_y},$self->{w}, $self->{h});
}

1
