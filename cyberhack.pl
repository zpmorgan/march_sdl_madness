#!/usr/bin/perl -w
use strict;

use SDL;
use SDLx::App; 
use SDLx::Sprite::Animated;
use SDL::Event;
use SDL::Events;

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



my $tiletypes = {
   'green' => {color => 0x00ff00ff},
   'red' =>  {color => 0xff0000ff},
   'air' =>  {solid => 0},
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
   default_solid => 'green',
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
   w => 1,
   h => 1,
);
$level->add_entity($cryptopod);
$viewport->track($cryptopod);
 



$app->add_event_handler(
   sub {
      my ($event,$app) = @_;
      $_[1]->stop if $_[0]->type == SDL_QUIT || $quit;

      my $key = $_[0]->key_sym;
      my $name = SDL::Events::get_key_name($key) if $key;

      if ( $_[0]->type == SDL_KEYDOWN ) {
         $pressed{$name} = 1;
      }
      elsif ( $_[0]->type == SDL_KEYUP ) {
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
         $cryptopod->set_status('freefall');
      }
      $cryptopod->do;
      $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x0 );
      $viewport->draw();
      
   }
);
$app->add_show_handler( sub { $app->update(); } );


$app->run();
