use bevy::{ecs::query, prelude::*};

#[derive(Component)]
struct Position {
    x: f32,
    y: f32,
}

#[derive(Component)]
struct Name(String);

#[derive(Component)]
struct Person;

struct Entity(u64);

fn main() {
    App::new()
        .add_plugins(DefaultPlugins) // https://bevyengine.org/learn/book/getting-started/plugins/
        .add_systems(Startup, add_people)
        .add_systems(PreUpdate, tick_timer)
        .add_systems(
            Update,
            (
                print_position_system,
                greet_people,
                print_positioned_people,
                print_timer,
            ),
        )
        .insert_resource(GreetTimer(Timer::from_seconds(2.0, TimerMode::Repeating)))
        .run();
}

fn add_people(mut commands: Commands) {
    commands.spawn((Person, Name("Elaina Proctor".to_string())));
    commands.spawn((Person, Name("Renzo Hume".to_string())));
    commands.spawn((Person, Name("Zayna Nieves".to_string())));

    commands.spawn((
        Person,
        Name("Sidney".to_string()),
        Position { x: 3.0, y: 4.0 },
    ));

    commands.spawn(Position { x: 1.0, y: 2.0 });
}

fn print_position_system(timer: Res<GreetTimer>, query: Query<&Position, Without<Person>>) {
    if timer.0.just_finished() {
        for position in &query {
            println!("position: {} {}", position.x, position.y);
        }
    }
}

fn print_positioned_people(timer: Res<GreetTimer>, query: Query<(&Position, &Name), With<Person>>) {
    if timer.0.just_finished() {
        for (position, name) in &query {
            println!("{} is at {} {}", name.0, position.x, position.y);
        }
    }
}

#[derive(Resource)]
struct GreetTimer(Timer);

fn tick_timer(time: Res<Time>, mut timer: ResMut<GreetTimer>) {
    timer.0.tick(time.delta());
}

fn greet_people(timer: Res<GreetTimer>, query: Query<&Name, With<Person>>) {
    if timer.0.just_finished() {
        for name in &query {
            println!("hello {}!", name.0);
        }
    }
}

fn print_timer(timer: Res<GreetTimer>) {
    if timer.0.just_finished() {
        println!("timer: {:?}", timer.0.elapsed());
    }
}
