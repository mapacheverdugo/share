import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:card_swiper/card_swiper.dart';
import 'package:collection/collection.dart';
import 'package:measure_size/measure_size.dart';
import 'package:separated_column/separated_column.dart';
import 'package:separated_row/separated_row.dart';

import 'package:lemu/shared/logging/main.dart';

class ListOrSwiper extends StatefulWidget {
  final List<Widget> children;
  final int itemAsListBreakpoint;
  final int swiperElementsPerPage;
  final double? childHeight;
  final Axis listDirection;
  final double swiperViewportFraction;
  final double swiperSpacing;
  final double listSpacing;
  final EdgeInsets padding;
  final Function(int)? onSwiperIndexChanged;

  const ListOrSwiper({
    Key? key,
    required this.children,
    this.childHeight,
    this.itemAsListBreakpoint = 1,
    this.swiperElementsPerPage = 1,
    this.listDirection = Axis.vertical,
    this.swiperViewportFraction = 0.90,
    this.swiperSpacing = 0,
    this.listSpacing = 0,
    this.padding = EdgeInsets.zero,
    this.onSwiperIndexChanged,
  }) : super(key: key);

  @override
  State<ListOrSwiper> createState() => _ListOrSwiperState();
}

class _ListOrSwiperState extends State<ListOrSwiper> {
  late double? _childHeight = widget.childHeight;

  bool get _showAsList => widget.children.length <= widget.itemAsListBreakpoint;

  double get _totalListMainAxisSpacing =>
      widget.listSpacing * (widget.children.length - 1);

  double get _totalListVerticalSpacing =>
      widget.listDirection == Axis.horizontal ? 0 : _totalListMainAxisSpacing;

  double get _totalListHorizontalSpacing =>
      widget.listDirection == Axis.horizontal ? _totalListMainAxisSpacing : 0;

  double get _totalSwiperPageMainAxisSpacing =>
      widget.swiperSpacing * (widget.swiperElementsPerPage - 1);

  double get _totalSwiperPageVerticalSpacing =>
      widget.listDirection == Axis.horizontal
          ? 0
          : _totalSwiperPageMainAxisSpacing;

  double get _totalSwiperPageHorizontalSpacing =>
      widget.listDirection == Axis.horizontal
          ? _totalSwiperPageMainAxisSpacing
          : 0;

  double _getListHeight(double childHeight) =>
      (widget.listDirection == Axis.horizontal
          ? childHeight
          : childHeight * widget.children.length) +
      _totalListVerticalSpacing +
      widget.padding.vertical;

  double _getSwiperHeight(double childHeight) =>
      (widget.listDirection == Axis.horizontal
          ? childHeight
          : childHeight * widget.swiperElementsPerPage) +
      _totalSwiperPageVerticalSpacing +
      widget.padding.vertical;

  double getListChildMaxWidth(double viewportWidth) {
    if (widget.listDirection == Axis.horizontal) {
      return (viewportWidth -
              _totalListHorizontalSpacing -
              widget.padding.horizontal) /
          widget.children.length;
    } else {
      return viewportWidth - widget.padding.horizontal;
    }
  }

  double getSwiperChildMaxWidth(double viewportWidth) {
    final swiperPageWidth = viewportWidth * widget.swiperViewportFraction;

    final result = (swiperPageWidth -
            widget.swiperSpacing -
            _totalSwiperPageHorizontalSpacing) /
        widget.swiperElementsPerPage;

    log('ListOrSwiper getSwiperChildMaxWidth result: $result');
    return result;
  }

  double getSimpleListChildMaxWidth(double constraintWidth) {
    final horizontalItems =
        widget.listDirection == Axis.horizontal ? widget.children.length : 1;

    final result = (constraintWidth -
            _totalListHorizontalSpacing -
            widget.padding.vertical) /
        horizontalItems;

    log('ListOrSwiper getSimpleListChildMaxWidth result: $result');
    return result;
  }

  double _getChildWidthAsList(double maxWidthConstraint) =>
      getListChildMaxWidth(maxWidthConstraint);

  double _getChildWidthAsSwiper(double maxWidthConstraint) =>
      getSwiperChildMaxWidth(maxWidthConstraint);

  Widget _buildSimpleList(
    List<Widget> children,
    double childHeight,
    double childWidth,
  ) {
    if (widget.listDirection == Axis.horizontal) {
      return SeparatedRow(
        separatorBuilder: (context, i) => SizedBox(width: widget.listSpacing),
        children: children
            .map(
              (e) => SizedBox(
                width: childWidth,
                height: childHeight,
                child: e,
              ),
            )
            .toList(),
      );
    } else {
      return SeparatedColumn(
        separatorBuilder: (context, i) => SizedBox(height: widget.listSpacing),
        children: children
            .map(
              (e) => SizedBox(
                width: childWidth,
                height: childHeight,
                child: e,
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildSwiperList(
    List<Widget> children,
    double childHeight,
    double childWidth,
  ) {
    if (widget.listDirection == Axis.horizontal) {
      return SeparatedRow(
        separatorBuilder: (context, i) => SizedBox(width: widget.swiperSpacing),
        children: children
            .map(
              (child) => SizedBox(
                width: childWidth,
                height: childHeight,
                child: child,
              ),
            )
            .toList(),
      );
    } else {
      return SeparatedColumn(
        separatorBuilder: (context, i) =>
            SizedBox(height: widget.swiperSpacing),
        children: children
            .map(
              (child) => SizedBox(
                width: childWidth,
                height: childHeight,
                child: child,
              ),
            )
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    log('MediaQuery.of(context).size.width: ${MediaQuery.of(context).size.width}');

    return LayoutBuilder(
      builder: (context, constraints) {
        final childWidthAsList = _getChildWidthAsList(constraints.maxWidth);
        final childWidthAsSwiper = _getChildWidthAsSwiper(constraints.maxWidth);

        Logger.logDebug('ListOrSwiper _showAsList is $_showAsList');

        final childWidth = _showAsList ? childWidthAsList : childWidthAsSwiper;

        Logger.logDebug('ListOrSwiper childWidth is $childWidth');

        if (_childHeight == null) {
          Logger.logDebug('ListOrSwiper _childHeight is null');

          return Opacity(
            opacity: 0,
            child: MeasureSize(
              onChange: (newSize) {
                Logger.logDebug('ListOrSwiper newSize: $newSize');
                setState(() {
                  _childHeight = newSize.height;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.children
                          .map(
                            (e) => SizedBox(
                              width: childWidth,
                              child: e,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          final listHeight = _getListHeight(_childHeight!);
          final swiperHeight = _getSwiperHeight(_childHeight!);

          if (_showAsList) {
            return Container(
              height: listHeight,
              margin: widget.padding,
              child: _buildSimpleList(
                widget.children,
                _childHeight!,
                childWidth,
              ),
            );
          } else {
            final slicedChildrens =
                widget.children.slices(widget.swiperElementsPerPage).toList();
            return SizedBox(
              height: swiperHeight,
              child: Swiper(
                viewportFraction: widget.swiperViewportFraction,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(
                      right: widget.swiperSpacing,
                    ),
                    child: _buildSwiperList(
                      slicedChildrens[index],
                      _childHeight!,
                      childWidth,
                    ),
                  );
                },
                itemCount: slicedChildrens.length,
                physics: const BouncingScrollPhysics(),
                loop: false,
                allowImplicitScrolling: true,
                onIndexChanged: widget.onSwiperIndexChanged,
              ),
            );
          }
        }
      },
    );
  }
}
