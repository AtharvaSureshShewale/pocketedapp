import 'package:flutter/material.dart';

class DraggableAssistiveButton extends StatefulWidget {
  final VoidCallback onTap;
  final List<String> allowedRoutes;
  final String currentRoute;

  const DraggableAssistiveButton({
    super.key,
    required this.onTap,
    required this.allowedRoutes,
    required this.currentRoute,
  });

  @override
  State<DraggableAssistiveButton> createState() => _DraggableAssistiveButtonState();
}

class _DraggableAssistiveButtonState extends State<DraggableAssistiveButton> {
  double top = 500;
  double left = 20;

  @override
  Widget build(BuildContext context) {
    if (!widget.allowedRoutes.contains(widget.currentRoute)) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: top,
      left: left,
      child: Draggable(
        feedback: buildButton(),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          final size = MediaQuery.of(context).size;
          setState(() {
            left = details.offset.dx.clamp(0, size.width - 70);
            top = details.offset.dy.clamp(0, size.height - 70);
          });
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: buildButton(),
        ),
      ),
    );
  }

  Widget buildButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.6),
      ),
      child: const Icon(Icons.smart_toy, color: Colors.white),
    );
  }
}
