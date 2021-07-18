import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_snake_game/direction_type.dart';

import 'control_panel.dart';
import 'direction.dart';
import 'piece.dart';

class GamePage extends StatefulWidget {
  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  List<Offset> positions = [];
  int length = 5;
  int step = 20;
  Direction direction = Direction.right;

  Piece food;
  Offset foodPosition;

  double screenWidth;
  double screenHeight;
  int lowerBoundX, upperBoundX, lowerBoundY, upperBoundY;

  Timer timer;
  double speed = 1;

  int score = 0;

  void draw() async {
    // if positions is empty, generate a random position and start the process

    if (positions.length == 0) {
      positions.add(getRandomPositionWithinRange());
    }

    // if the snake just ate. it's length increases.
    // The while loop adds a new position to positions
    // so that length and positions are always in sync.
    while (length > positions.length) {
      positions.add(positions[positions.length - 1]);
    }
    // It checks positions‘s length and shifts each position.
    // This creates the illusion that the snake is moving.
    for (var i = positions.length - 1; i > 0; i--) {
      positions[i] = positions[i - 1];
    }

    // call getNextPosition() on the first item
    // this moves the first piece, the head of the snake, to a new position.
    positions[0] = await getNextPosition(positions[0]);
  }

  //* Returns a Direction, use it to move the snake in a random direction at spawn
  //* Optional argument to define if the directions horizontal or vertical
  Direction getRandomDirection([DirectionType type]) {
    if (type == DirectionType.horizontal) {
      bool random = Random().nextBool();
      if (random) {
        return Direction.right;
      } else {
        return Direction.left;
      }
    } else if (type == DirectionType.vertical) {
      bool random = Random().nextBool();
      if (random) {
        return Direction.up;
      } else {
        return Direction.down;
      }
    } else {
      int random = Random().nextInt(4);
      return Direction.values[random];
    }
  }

  //* generates a random positions on the screen within the bounds of the screen
  //* Use this function to spawn a new snake and food for the snake.
  Offset getRandomPositionWithinRange() {
    int posX = Random().nextInt(upperBoundX) + lowerBoundX;
    int posY = Random().nextInt(upperBoundY) + lowerBoundY;
    return Offset(roundToNearestTens(posX).toDouble(),
        roundToNearestTens(posY).toDouble());
  }

  bool detectCollision(Offset position) {
    if (position.dx >= upperBoundX && direction == Direction.right) {
      return true;
    } else if (position.dx <= lowerBoundX && direction == Direction.left) {
      return true;
    } else if (position.dy >= upperBoundY && direction == Direction.down) {
      return true;
    } else if (position.dy <= lowerBoundY && direction == Direction.up) {
      return true;
    }

    return false;
  }

  //* Displays a dialog when the snake collides with any of the boundaries
  //* it displays the user score and a button to restart the game
  void showGameOverDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Colors.black,
                width: 3.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          title: Text(
            "Game Over",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Your game is over but you played well. Your score is " +
                score.toString() +
                ".",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            FlatButton(
              onPressed: () async {
                Navigator.of(context).pop();
                restart();
              },
              child: Text(
                "Restart",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  //* 1. Creates a new position for the object based on the object’s
  //* current position and the value of its direction.
  //* Changing the direction causes the object to move in a different direction.
  //* You’ll use control buttons to do this later.
  //* 2. Increases the value of the x-coordinate if the direction is set to
  //* right and decreases the value if the direction is set to left.
  //* 3. Similarly, increases the value of the y-coordinate if the direction
  //* is set to up decreases it if the direction is set to down.
  Future<Offset> getNextPosition(Offset position) async {
    Offset nextPosition;

    if (detectCollision(position) == true) {
      if (timer != null && timer.isActive) timer.cancel();
      await Future.delayed(
          Duration(milliseconds: 500), () => showGameOverDialog());
      return position;
    }

    if (direction == Direction.right) {
      nextPosition = Offset(position.dx + step, position.dy);
    } else if (direction == Direction.left) {
      nextPosition = Offset(position.dx - step, position.dy);
    } else if (direction == Direction.up) {
      nextPosition = Offset(position.dx, position.dy - step);
    } else if (direction == Direction.down) {
      nextPosition = Offset(position.dx, position.dy + step);
    }

    return nextPosition;
  }

  void drawFood() {
    if (foodPosition == null) {
      foodPosition = getRandomPositionWithinRange();
    }

    if (foodPosition == positions[0]) {
      length++;
      speed = speed + 0.25;
      score = score + 5;
      changeSpeed();

      foodPosition = getRandomPositionWithinRange();
    }

    food = Piece(
      posX: foodPosition.dx.toInt(),
      posY: foodPosition.dy.toInt(),
      size: step,
      color: Colors.red,
      isAnimated: true,
    );
  }

  //* create a list based on the position of the snake on the screen
  //* store the positions of all the pieces that make up the snake in a list called positions
  //* reads positions and returns a list of pieces.
  List<Piece> getPieces() {
    final pieces = <Piece>[];
    draw();
    drawFood();

    // cover the entire length of the snake
    for (var i = 0; i < length; i++) {
      // handle edge case where the length of the snake
      // doesnt match the length of positions
      if (i >= positions.length) {
        continue;
      }
      // for each iteration, create a piece with the correct position
      // and add it to pieces list
      pieces.add(
        Piece(
          posX: positions[i].dx.toInt(),
          posY: positions[i].dy.toInt(),
          // The size is step, in this case, which ensures that the Snake moves
          // along a grid where each grid cell has the size step
          size: step,
          color: Colors.green,
        ),
      );
    }

    return pieces;
  }

  //* implements Control Panel
  //* displays four circular btns on the screen to control movement of snake
  Widget getControls() {
    return ControlPanel(
      onTapped: (Direction newDirection) {
        direction = newDirection;
      },
    );
  }

  //* Rounds off the passed in integer to the nearest 'step' value
  //* This allows to get the exact next position that is 'step' units away
  //* from the current position on an imaginary grid.
  int roundToNearestTens(int num) {
    int divisor = step;
    int output = (num ~/ divisor) * divisor;
    if (output == 0) {
      output += step;
    }
    return output;
  }

  //* resets the timer with a duration that factors in speed.
  //* You control speed and increase it every time the snake eats the food.
  //* Finally, on every tick of the timer, you call setState(),
  //* which rebuilds the whole UI.
  //* This happens at a rate you control using speed.
  void changeSpeed() {
    if (timer != null && timer.isActive) timer.cancel();

    timer = Timer.periodic(Duration(milliseconds: 200 ~/ speed), (timer) {
      setState(() {});
    });
  }

  Widget getScore() {
    return Positioned(
      top: 50.0,
      right: 40.0,
      child: Text(
        "Score: " + score.toString(),
        style: TextStyle(fontSize: 24.0),
      ),
    );
  }

  void restart() {
    score = 0;
    length = 5;
    positions = [];
    direction = getRandomDirection();
    speed = 1;
    changeSpeed();
  }

  //* Draws a border along the edge of the screen to represent the play area
  Widget getPlayAreaBorder() {
    return Positioned(
      top: lowerBoundY.toDouble(),
      left: lowerBoundX.toDouble(),
      child: Container(
        width: (upperBoundX - lowerBoundX + step).toDouble(),
        height: (upperBoundY - lowerBoundY + step).toDouble(),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black.withOpacity(0.2),
            style: BorderStyle.solid,
            width: 1.0,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    restart();
  }

  @override
  Widget build(BuildContext context) {
    // get the device size
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    lowerBoundX = step;
    lowerBoundY = step;
    upperBoundX = roundToNearestTens(screenWidth.toInt() - step);
    upperBoundY = roundToNearestTens(screenHeight.toInt() - step);

    return Scaffold(
      body: Container(
        color: Colors.amber,
        child: Stack(
          children: [
            getPlayAreaBorder(),
            Stack(
              children: getPieces(),
            ),
            getControls(),
            food,
            getScore(),
          ],
        ),
      ),
    );
  }
}
