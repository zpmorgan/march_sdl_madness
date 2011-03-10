package Viewport;
use warnings;
use strict;

use SDL::Rect;

use POSIX qw/floor ceil/; 

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
   my $level = $self->{level};
   #my %params = @_;
   
   my $trackee = $self->{track};
   # scroll if necessary
   if ($trackee){
      my ($cx,$cy) = $trackee->center;
      $self->{level_x} = $cx - $self->{w}/(2*32);
      $self->{level_y} = $cy - $self->{h}/(2*32);
   }
   
   my $vp_app_rect = $self->app_rect();
   
   #make sure we have these parameters
   for (qw/ w h level_x level_y  surf_x  surf_y /){
      die "viewport draw needs $_" unless defined $self->{$_};
   }
   
   #figure out 2d range of tiles within viewport bounds
   my $tile_start_x = $self->{level_x};
   my $tile_end_x = 1 + ceil ($self->{level_x} + $self->{w}/32);
   my $tile_start_y = $self->{level_y};
   my $tile_end_y = 1 + ceil ($self->{level_y} + $self->{w}/32);
   $tile_start_x = 0 if $tile_start_x < 0; 
   $tile_end_x = $level->{w}-1 if $tile_end_x  >= $level->{w};
   $tile_start_y = 0 if $tile_start_y < 0; 
   $tile_end_y = $level->{h}-1 if $tile_end_y  >= $level->{h};
   
   for my $ty ($tile_start_y .. $tile_end_y){
      for my $tx ($tile_start_x .. $tile_end_x){
         my $tile = $self->{level}{tiles}[$ty][$tx] // $self->{default_tile};
         #die @{$self->{tiles}} unless defined $tile;
         my $tileclass = $self->{level}{tiletypes}{$tile} || die "tile $tile what?";
         
         my $tile_rect = SDL::Rect->new(($tx-$self->{level_x})*32,($ty-$self->{level_y})*32, 32, 32 );
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
      # set sprite rect relative to viewport
      $ent->sprite->rect (
         SDLx::Rect->new(
            ($ent->x-$self->{level_x})*32, 
            ($ent->y-$self->{level_y})*32, 
            16, 32 ) );
      $ent->sprite->rect->clip_ip ($vp_app_rect);
     # die $ent->sprite->y;
      $ent->sprite->draw ($self->{app}->surface);
   }
   $self->draw_border;
}

sub tilesize{
   return $_[0]{level}{tilesize};
}
sub app_rect{
   my $self = shift;
   return new SDLx::Rect($self->{surf_x}, $self->{surf_y},$self->{w}, $self->{h});
}

sub track{
   my ($self,$thing) = @_;
   $self->{track} = $thing;
}


use SDL::GFX::Primitives;

sub draw_border{
   my $self = shift;
   my ($sx,$sy,$w,$h) = @{$self}{qw/ surf_x  surf_y  w h /};
   SDL::GFX::Primitives::hline_RGBA(  
      $self->{app}, $sx, $sx+$w, $sy,    255,255,255,255 );
   SDL::GFX::Primitives::hline_RGBA(  
      $self->{app}, $sx, $sx+$w, $sy+$h, 255,255,255,255 );
   SDL::GFX::Primitives::vline_RGBA(  
      $self->{app}, $sx,    $sy, $sy+$h, 255,255,255,255 );
   SDL::GFX::Primitives::vline_RGBA(  
      $self->{app}, $sx+$w, $sy, $sy+$h, 255,255,255,255 );
}

1
