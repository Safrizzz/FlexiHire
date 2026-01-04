import 'dart:async';
import 'package:flutter/material.dart';
import '../services/location_service.dart';

/// A widget for selecting a location with address search and auto-complete
class LocationPickerField extends StatefulWidget {
  final String? initialAddress;
  final GeoLocation? initialGeoLocation;
  final Function(String address, GeoLocation? geoLocation) onLocationChanged;
  final String labelText;
  final String? hintText;
  final bool isRequired;

  const LocationPickerField({
    super.key,
    this.initialAddress,
    this.initialGeoLocation,
    required this.onLocationChanged,
    this.labelText = 'Location',
    this.hintText,
    this.isRequired = true,
  });

  @override
  State<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<LocationPickerField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;
  GeoLocation? _selectedGeoLocation;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialAddress ?? '';
    _selectedGeoLocation = widget.initialGeoLocation;

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hideOverlay();
        // Geocode the address if user typed something without selecting
        _geocodeCurrentAddress();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    _hideOverlay();
    super.dispose();
  }

  void _onTextChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      _hideOverlay();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _isLoading = true);

    try {
      final results = await LocationService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
          _showSuggestions = results.isNotEmpty;
        });

        if (_showSuggestions) {
          _showOverlay();
        } else {
          _hideOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _suggestions = [];
        });
      }
    }
  }

  Future<void> _geocodeCurrentAddress() async {
    final address = _controller.text.trim();
    if (address.isEmpty || _selectedGeoLocation != null) return;

    setState(() => _isGeocoding = true);

    try {
      final location = await LocationService.geocodeAddress(address);
      if (mounted) {
        setState(() {
          _selectedGeoLocation = location;
          _isGeocoding = false;
        });
        widget.onLocationChanged(address, location);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeocoding = false);
      }
    }
  }

  void _selectSuggestion(PlaceSuggestion suggestion) {
    // Get a shorter display name (take first 2-3 parts)
    final parts = suggestion.displayName.split(',');
    final shortName = parts.take(3).join(',').trim();

    _controller.text = shortName;
    _selectedGeoLocation = suggestion.location;

    widget.onLocationChanged(shortName, suggestion.location);

    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    _hideOverlay();
    _focusNode.unfocus();
  }

  void _showOverlay() {
    _hideOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getFieldWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return InkWell(
                    onTap: () => _selectSuggestion(suggestion),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              suggestion.displayName,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getFieldWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: (value) {
          _selectedGeoLocation = null; // Clear geo when user types
          _onTextChanged(value);
        },
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText ?? 'Search for a location...',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.location_on_outlined),
          suffixIcon: _buildSuffixIcon(),
        ),
        validator: widget.isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a location';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (_isLoading || _isGeocoding) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_selectedGeoLocation != null && _selectedGeoLocation!.isValid) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    if (_controller.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          _controller.clear();
          _selectedGeoLocation = null;
          widget.onLocationChanged('', null);
          setState(() {
            _suggestions = [];
            _showSuggestions = false;
          });
          _hideOverlay();
        },
      );
    }

    return null;
  }
}

/// A simple dialog to pick location with a larger search area
class LocationPickerDialog extends StatefulWidget {
  final String? initialAddress;
  final GeoLocation? initialGeoLocation;

  const LocationPickerDialog({
    super.key,
    this.initialAddress,
    this.initialGeoLocation,
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();

  /// Show the location picker dialog and return the selected location
  static Future<LocationPickerResult?> show(
    BuildContext context, {
    String? initialAddress,
    GeoLocation? initialGeoLocation,
  }) {
    return showDialog<LocationPickerResult>(
      context: context,
      builder: (context) => LocationPickerDialog(
        initialAddress: initialAddress,
        initialGeoLocation: initialGeoLocation,
      ),
    );
  }
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  String _address = '';
  GeoLocation? _geoLocation;

  @override
  void initState() {
    super.initState();
    _address = widget.initialAddress ?? '';
    _geoLocation = widget.initialGeoLocation;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Location'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocationPickerField(
              initialAddress: widget.initialAddress,
              initialGeoLocation: widget.initialGeoLocation,
              onLocationChanged: (address, geoLocation) {
                setState(() {
                  _address = address;
                  _geoLocation = geoLocation;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_geoLocation != null && _geoLocation!.isValid)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coordinates: ${_geoLocation!.latitude.toStringAsFixed(4)}, ${_geoLocation!.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _address.isNotEmpty
              ? () {
                  Navigator.pop(
                    context,
                    LocationPickerResult(
                      address: _address,
                      geoLocation: _geoLocation,
                    ),
                  );
                }
              : null,
          child: const Text('Select'),
        ),
      ],
    );
  }
}

/// Result from the location picker dialog
class LocationPickerResult {
  final String address;
  final GeoLocation? geoLocation;

  LocationPickerResult({required this.address, this.geoLocation});
}
