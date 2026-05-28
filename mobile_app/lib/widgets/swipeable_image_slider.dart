import 'package:flutter/material.dart';

class SwipeableImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  final String heroTagPrefix;
  final Function(int)? onTapImage;
  final double aspectRatio;
  final BoxFit fit;

  const SwipeableImageSlider({
    super.key,
    required this.imageUrls,
    required this.heroTagPrefix,
    this.onTapImage,
    this.aspectRatio = 1.0,
    this.fit = BoxFit.cover,
  });

  @override
  State<SwipeableImageSlider> createState() => _SwipeableImageSliderState();
}

class _SwipeableImageSliderState extends State<SwipeableImageSlider> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          color: Colors.grey[200],
          child: const Icon(Icons.image, size: 80, color: Colors.grey),
        ),
      );
    }

    if (widget.imageUrls.length == 1) {
      return GestureDetector(
        onTap: () {
          if (widget.onTapImage != null) {
            widget.onTapImage!(0);
          }
        },
        child: Hero(
          tag: '${widget.heroTagPrefix}-0',
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: Image.network(
              widget.imageUrls[0],
              fit: widget.fit,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  if (widget.onTapImage != null) {
                    widget.onTapImage!(index);
                  }
                },
                child: Hero(
                  tag: '${widget.heroTagPrefix}-$index',
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: widget.fit,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          ),
          // Slide index counter overlay (e.g. 1/3)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Dots indicator overlay
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) => Container(
                  width: _currentIndex == index ? 8.0 : 6.0,
                  height: _currentIndex == index ? 8.0 : 6.0,
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? const Color(0xFF2E7D32)
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
