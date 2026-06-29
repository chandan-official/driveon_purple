import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PickedPlace {
  final String address;
  final double lat;
  final double lng;

  const PickedPlace({
    required this.address,
    required this.lat,
    required this.lng,
  });
}

class PlacePickerField extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final Color iconColor;
  final void Function(PickedPlace place) onPicked;
  final PickedPlace? initialValue;
  final Color? fillColor;

  const PlacePickerField({
    super.key,
    required this.hintText,
    required this.icon,
    required this.iconColor,
    required this.onPicked,
    this.initialValue,
    this.fillColor,
  });

  @override
  State<PlacePickerField> createState() => _PlacePickerFieldState();
}

class _PlacePickerFieldState extends State<PlacePickerField> {
  late final TextEditingController _controller;

  String get _apiKey => (dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '').trim();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue?.address ?? "");
  }

  @override
  void didUpdateWidget(covariant PlacePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue?.address != widget.initialValue?.address) {
      _controller.text = widget.initialValue?.address ?? "";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // _autocomplete method removed to be used within bottom sheet

  Future<PickedPlace?> _placeDetails(String placeId) async {
    final uri = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/details/json"
      "?place_id=${Uri.encodeQueryComponent(placeId)}"
      "&fields=formatted_address,geometry/location"
      "&key=$_apiKey",
    );

    final res = await http.get(uri);
    final data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception("Details HTTP ${res.statusCode}");
    }

    final status = (data["status"] ?? "").toString();
    if (status != "OK") {
      final msg = (data["error_message"] ?? status).toString();
      throw Exception("Details failed: $msg");
    }

    final result = data["result"] as Map<String, dynamic>? ?? {};
    final addr = (result["formatted_address"] ?? "").toString();

    final loc = (((result["geometry"] ?? {})["location"]) ?? {}) as Map;
    final lat = (loc["lat"] as num?)?.toDouble();
    final lng = (loc["lng"] as num?)?.toDouble();

    if (lat == null || lng == null) return null;

    return PickedPlace(
      address: addr.isNotEmpty ? addr : "Selected Place",
      lat: lat,
      lng: lng,
    );
  }

  Future<void> _openSearch() async {
    if (_apiKey.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("GOOGLE_MAPS_API_KEY missing in .env")),
      );
      return;
    }

    try {
      final picked = await showModalBottomSheet<_Prediction>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (_) => _PlaceSearchSheet(apiKey: _apiKey),
      );

      if (picked == null) return;

      final details = await _placeDetails(picked.placeId);
      if (details == null) return;

      if (!mounted) return;
      setState(() => _controller.text = details.address);
      widget.onPicked(details);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Place picker error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      onTap: _openSearch,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(widget.icon, color: widget.iconColor),
        filled: true,
        fillColor: widget.fillColor,
        border: widget.fillColor != null 
          ? OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
          : null,
      ),
    );
  }
}

class _PlaceSearchSheet extends StatefulWidget {
  final String apiKey;
  const _PlaceSearchSheet({super.key, required this.apiKey});

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<_Prediction> _predictions = [];
  bool _isLoading = false;

  void _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=${Uri.encodeQueryComponent(query)}"
        "&components=country:in"
        "&key=${widget.apiKey}",
      );

      final res = await http.get(uri);
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final preds = (data["predictions"] as List? ?? const [])
            .map((e) => _Prediction.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _predictions = preds;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Search location...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: _search,
          ),
          const SizedBox(height: 16),
          if (_predictions.isEmpty && !_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Type a location to search", style: TextStyle(color: Colors.grey)),
            ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _predictions.length,
              itemBuilder: (context, i) {
                final p = _predictions[i];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.grey),
                  title: Text(p.description),
                  onTap: () => Navigator.pop(context, p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Prediction {
  final String placeId;
  final String description;

  const _Prediction({required this.placeId, required this.description});

  factory _Prediction.fromJson(Map<String, dynamic> json) {
    return _Prediction(
      placeId: (json["place_id"] ?? "").toString(),
      description: (json["description"] ?? "").toString(),
    );
  }
}
