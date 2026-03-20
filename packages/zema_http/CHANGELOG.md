## 0.1.0

- Initial release.
- `ZemaHttpResponseX` extension on `http.Response` with `.parse()` and `.safeParse()`.
- `safeParse` wraps `FormatException` as `ZemaFailure` with code `invalid_json` instead of throwing.
