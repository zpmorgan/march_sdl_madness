#!/usr/bin/perl -w
use strict;

#found some tiles at http://www.ironstarmedia.co.uk/2010/10/free-game-assets-13-prototype-mine-tileset/
# and some musics at http://www.ironstarmedia.co.uk/resources/free-game-assets/browse/music

use SDL;
use SDLx::App; 
use SDLx::Sprite::Animated;
use SDL::Event;
use SDL::Events;

use SDLx::Sound;

use Viewport;
use Level; 
use Entity;
use Carp;


my %pressed;
my $quit = 0;

my $app = SDLx::App->new( 
   title  => 'Application Title',
   width  => 640,
   height => 480,
   depth  => 32
); 

my $tiles_surf = SDLx::Surface->load('cave-tiles32.png');
my $rock_sprite = SDLx::Sprite->new(
   image => 'cave-tiles32.png',
   width => 32,
   height => 32,
);
my $air_sprite = SDLx::Sprite->new(
   image => 'cave-tiles32.png',
   width => 32,
   height => 32,
);
my $rock_clip = SDL::Rect->new( 32,32,32,32);
my $air_clip = SDL::Rect->new(160,0,32,32);
$tiles_surf->blit( $rock_sprite->surface, $rock_clip, $rock_sprite->clip );
$tiles_surf->blit( $air_sprite->surface, $air_clip, $air_sprite->clip );

my $tiletypes = {
   'green' => {color => 0x00ff00ff},
   'rocks'  => {color => 0x00ff00ff},
   'rock'  => {sprite => $rock_sprite},
   'red' =>  {color => 0xff0000ff},
   #'air' =>  {solid => 0},
   'air' =>  {sprite => $air_sprite, solid=>0},
};


#~ my $levelsize = 20;
#~ my @leveldata = map{[map {'air'} 1..20]} 1..20;
#~ for(0..19){
   #~ $leveldata[8][$_] = 'green';
   #~ $leveldata[rand(19)][rand(20)] = 'red';
#~ }
my $level = Level->new(
   size => 120,
   tilesize => 32,
   tiletypes => $tiletypes, 
   #~ tiles => \@leveldata, 
   default_tile => 'air',
   default_space => 'air',
   default_solid => 'rock',
);

#~ $level->generate_terrain;

$level->init_collision_grid;

my $viewport = $level->basic_viewport (app => $app, level => $level, 
      w=>500, h=>400, surf_x => 32,  surf_y=> 32);

my $sprite = SDLx::Sprite::Animated->new(
   name            => 'cryptopod',
   image           => 'cryptopod.png',
   rect            => SDL::Rect->new( 0, 0, 16, 32 ),
   ticks_per_frame => 4,
);

$sprite->set_sequences(
    move  => [ [ 0, 0 ], [ 1, 0 ] ],
);

$sprite->sequence('move');
$sprite->start();

my $cryptopod = new Entity(
   x => 3,
   y => 3,
   sprite => $sprite,
   w => .5,
   h => 1,
);
$level->add_entity($cryptopod);
$viewport->track($cryptopod);
 

my $snd = SDLx::Sound->new();
# load and play a sound
my $play = $snd->play('hallucinations.ogg');
#Hallucinations track from : 
# http://modarchive.org/index.php?request=view_by_moduleid&query=58827
# Artist unknown :\

$app->add_event_handler(
   sub {
      my ($event,$app) = @_;
      exit if $event->type == SDL_QUIT || $quit;

      my $key = $event->key_sym;
      my $name = SDL::Events::get_key_name($key) if $key;

      if ( $event->type == SDL_KEYDOWN ) {
         $pressed{$name} = 1;
      }
      elsif ( $event->type == SDL_KEYUP ) {
         $pressed{$name} = 0;
      }
   }
);


$app->add_show_handler(
   sub {
      
      #moving left ot right?
      if ($pressed{right} and ! $pressed{left}){
         $cryptopod->xv(.2);
      }
      elsif ($pressed{left} and ! $pressed{right}){
         $cryptopod->xv(-.2);
      }
      else {
          $cryptopod->xv(0);
      }
      
      # jumping?
      if ($pressed{up} and $cryptopod->status eq 'walking'){
         $cryptopod->yv(-.3);
         $cryptopod->{y} -= .001;
         $cryptopod->set_freefall;
      }
      $cryptopod->do;
      $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x0 );
      $viewport->draw();
      
   }
);
$app->add_show_handler( sub { $app->update(); } );


$app->run();
