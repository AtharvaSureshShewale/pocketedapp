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
  bool isDragging = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.allowedRoutes.contains(widget.currentRoute)) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      top: top,
      left: left,
      child: GestureDetector(
        onPanStart: (_) => setState(() => isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            left = (left + details.delta.dx).clamp(0.0, screenSize.width - 70);
            top = (top + details.delta.dy).clamp(0.0, screenSize.height - 70);
          });
        },
        onPanEnd: (_) => setState(() => isDragging = false),
        onTap: widget.onTap,
        child: buildButton(),
      ),
    );
  }

  Widget buildButton() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDragging ? 0.7 : 1.0,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(2, 2),
            )
          ],
        ),
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
    );
  }
}
