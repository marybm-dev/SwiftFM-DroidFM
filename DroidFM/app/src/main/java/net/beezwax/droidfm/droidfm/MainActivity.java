package net.beezwax.droidfm.droidfm;

import android.app.Fragment;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.app.FragmentManager;
import android.support.v7.widget.Toolbar;
import android.view.View;
import android.widget.ListView;

public class MainActivity extends AppCompatActivity {
    public Fragment fragment = null;
    public View view;
    public ListView listView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayShowHomeEnabled(true);
            getSupportActionBar().setIcon(R.mipmap.ic_launcher);
        }

        view = this.findViewById(android.R.id.content);
        listView = (ListView) this.findViewById(R.id.listview);

        if (savedInstanceState == null) {
            selectItem(0);
        }
    }

    public void selectItem(int position) {
        switch (position) {
            case 0:
                fragment = new DroidFMListView();
                break;
            default:
                break;
        }

        // change Fragment
        FragmentManager fragManager = getFragmentManager();
        fragManager.beginTransaction().add(R.id.content_frame, fragment).commit();
    }
}